-- Database fixes and optimizations
-- Fixes critical RLS issues, adds missing indexes, creates RPC functions

-- 1. DELETE RLS on profiles (fixes account deletion)
DO $$ BEGIN
  CREATE POLICY "Users can delete own profile" ON profiles
    FOR DELETE TO authenticated USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. Fix watch_history UNIQUE with COALESCE (fixes duplicate movie entries)
DROP INDEX IF EXISTS watch_history_user_id_tmdb_id_media_type_season_number_episode_number_key;
DROP INDEX IF EXISTS watch_history_unique_idx;
CREATE UNIQUE INDEX watch_history_unique_idx ON watch_history 
  (user_id, tmdb_id, media_type, COALESCE(season_number, 0), COALESCE(episode_number, 0));

-- 3. UPDATE RLS on watch_history (fixes re-marking episodes)
DO $$ BEGIN
  CREATE POLICY "Users can update own watch history" ON watch_history
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 4. UPDATE RLS on favorite_actor_votes (fixes changing votes)
DO $$ BEGIN
  CREATE POLICY "Users can update own favorite actor votes" ON favorite_actor_votes
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
GRANT UPDATE ON favorite_actor_votes TO authenticated;

-- 5. UPDATE RLS on follows (fixes upsert on existing follow)
DO $$ BEGIN
  CREATE POLICY "Users can update own follows" ON follows
    FOR UPDATE TO authenticated USING (auth.uid() = follower_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 6. UPDATE RLS on comment_likes (fixes re-liking)
DO $$ BEGIN
  CREATE POLICY "Users can update own comment likes" ON comment_likes
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 7. UPDATE RLS on shared_list_members (allows role changes by admin)
DO $$ BEGIN
  CREATE POLICY "Admins can update member roles" ON shared_list_members
    FOR UPDATE TO authenticated USING (
      EXISTS (SELECT 1 FROM shared_list_members slm 
              WHERE slm.list_id = shared_list_members.list_id 
              AND slm.user_id = auth.uid() AND slm.role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 8. Index on ratings(user_id) for faster queries
CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON ratings(user_id);

-- 9. RPC: get_average_rating (replaces client-side average of 1000 rows)
CREATE OR REPLACE FUNCTION get_average_rating(p_tmdb_id INTEGER, p_media_type TEXT)
RETURNS NUMERIC AS $$
  SELECT COALESCE(AVG(rating), 0) FROM ratings 
  WHERE tmdb_id = p_tmdb_id AND media_type = p_media_type;
$$ LANGUAGE sql STABLE;

-- 10. RPC: get_following_watch_hours (replaces N+1 queries)
CREATE OR REPLACE FUNCTION get_following_watch_hours(p_user_id UUID)
RETURNS TABLE(user_id UUID, username TEXT, avatar_url TEXT, total_hours NUMERIC, is_me BOOLEAN) AS $$
  SELECT result_user_id, result_username, result_avatar_url, result_hours, result_is_me FROM (
    SELECT f.following_id AS result_user_id, p.username AS result_username, p.avatar_url AS result_avatar_url,
      COALESCE(SUM(CASE WHEN wh.media_type = 'tv' THEN 45 ELSE 120 END), 0) / 60.0 AS result_hours,
      FALSE AS result_is_me
    FROM follows f JOIN profiles p ON p.id = f.following_id
    LEFT JOIN watch_history wh ON wh.user_id = f.following_id
    WHERE f.follower_id = p_user_id
    GROUP BY f.following_id, p.username, p.avatar_url
    UNION ALL
    SELECT p.id AS result_user_id, p.username AS result_username, p.avatar_url AS result_avatar_url,
      COALESCE(SUM(CASE WHEN wh.media_type = 'tv' THEN 45 ELSE 120 END), 0) / 60.0 AS result_hours,
      TRUE AS result_is_me
    FROM profiles p LEFT JOIN watch_history wh ON wh.user_id = p.id
    WHERE p.id = p_user_id GROUP BY p.id, p.username, p.avatar_url
  ) sub
  ORDER BY result_hours DESC;
$$ LANGUAGE sql STABLE;

-- 11. DB View: comments_with_likes (replaces 2 queries + client-side compute)
CREATE OR REPLACE VIEW comments_with_likes AS
  SELECT c.*, COUNT(cl.id) AS likes_count
  FROM comments c LEFT JOIN comment_likes cl ON cl.comment_id = c.id
  GROUP BY c.id;
