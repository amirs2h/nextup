-- ============================================================
-- MIGRATION: Complete database fix for NextUp
-- Run this ONCE in Supabase SQL Editor
-- ============================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 2. UNIQUE CONSTRAINTS (required for upsert onConflict)
-- ============================================================

-- watchlist: unique per user+tmdb+media+list
ALTER TABLE public.watchlist DROP CONSTRAINT IF EXISTS watchlist_unique_key;
ALTER TABLE public.watchlist 
  ADD CONSTRAINT watchlist_unique_key 
  UNIQUE (user_id, tmdb_id, media_type, list_name);

-- watch_history: unique per user+tmdb+media+season+episode
-- Use COALESCE to handle NULL values
CREATE UNIQUE INDEX IF NOT EXISTS watch_history_unique_key 
  ON public.watch_history (user_id, tmdb_id, media_type, 
    COALESCE(season_number, 0), COALESCE(episode_number, 0));

-- favorites: unique per user+tmdb+media
ALTER TABLE public.favorites DROP CONSTRAINT IF EXISTS favorites_unique_key;
ALTER TABLE public.favorites 
  ADD CONSTRAINT favorites_unique_key 
  UNIQUE (user_id, tmdb_id, media_type);

-- follows: unique per follower+following
ALTER TABLE public.follows DROP CONSTRAINT IF EXISTS follows_unique_key;
ALTER TABLE public.follows 
  ADD CONSTRAINT follows_unique_key 
  UNIQUE (follower_id, following_id);

-- follows: prevent self-follow
ALTER TABLE public.follows DROP CONSTRAINT IF EXISTS follows_no_self_follow;
ALTER TABLE public.follows 
  ADD CONSTRAINT follows_no_self_follow 
  CHECK (follower_id != following_id);

-- comment_likes: unique per user+comment
ALTER TABLE public.comment_likes DROP CONSTRAINT IF EXISTS comment_likes_unique_key;
ALTER TABLE public.comment_likes 
  ADD CONSTRAINT comment_likes_unique_key 
  UNIQUE (user_id, comment_id);

-- reactions: unique per user+episode
ALTER TABLE public.reactions DROP CONSTRAINT IF EXISTS reactions_unique_key;
ALTER TABLE public.reactions 
  ADD CONSTRAINT reactions_unique_key 
  UNIQUE (user_id, tmdb_id, season_number, episode_number);

-- shared_list_members: unique per list+user
ALTER TABLE public.shared_list_members DROP CONSTRAINT IF EXISTS shared_list_members_unique_key;
ALTER TABLE public.shared_list_members 
  ADD CONSTRAINT shared_list_members_unique_key 
  UNIQUE (list_id, user_id);

-- shared_list_items: unique per list+tmdb+media
ALTER TABLE public.shared_list_items DROP CONSTRAINT IF EXISTS shared_list_items_unique_key;
ALTER TABLE public.shared_list_items 
  ADD CONSTRAINT shared_list_items_unique_key 
  UNIQUE (list_id, tmdb_id, media_type);

-- custom_list_items: unique per list+tmdb+media
ALTER TABLE public.custom_list_items DROP CONSTRAINT IF EXISTS custom_list_items_unique_key;
ALTER TABLE public.custom_list_items 
  ADD CONSTRAINT custom_list_items_unique_key 
  UNIQUE (list_id, tmdb_id, media_type);

-- character_votes: unique per user+person+tmdb+character
ALTER TABLE public.character_votes DROP CONSTRAINT IF EXISTS character_votes_unique_key;
ALTER TABLE public.character_votes 
  ADD CONSTRAINT character_votes_unique_key 
  UNIQUE (user_id, person_id, tmdb_id, character_name);

-- favorite_actor_votes: unique per user+tmdb+media
ALTER TABLE public.favorite_actor_votes DROP CONSTRAINT IF EXISTS favorite_actor_votes_unique_key;
ALTER TABLE public.favorite_actor_votes 
  ADD CONSTRAINT favorite_actor_votes_unique_key 
  UNIQUE (user_id, tmdb_id, media_type);

-- ratings: unique per user+tmdb+media+season+episode
CREATE UNIQUE INDEX IF NOT EXISTS ratings_unique_user_media_episode
  ON public.ratings (user_id, tmdb_id, media_type, 
    COALESCE(season_number, 0), COALESCE(episode_number, 0));

-- ============================================================
-- 3. INDEXES for performance
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_watchlist_user_id ON public.watchlist(user_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_media_type ON public.watchlist(media_type);
CREATE INDEX IF NOT EXISTS idx_watchlist_status ON public.watchlist(status);
CREATE INDEX IF NOT EXISTS idx_watch_history_user_id ON public.watch_history(user_id);
CREATE INDEX IF NOT EXISTS idx_watch_history_tmdb_id ON public.watch_history(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_tmdb_id ON public.comments(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_comments_media_type ON public.comments(media_type);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON public.comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_reactions_tmdb_id ON public.reactions(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_reactions_episode ON public.reactions(tmdb_id, season_number, episode_number);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_custom_lists_user_id ON public.custom_lists(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_lists_creator_id ON public.shared_lists(creator_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON public.ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_tmdb_media ON public.ratings(tmdb_id, media_type);
CREATE INDEX IF NOT EXISTS idx_character_votes_user_id ON public.character_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_character_votes_person_id ON public.character_votes(person_id);
CREATE INDEX IF NOT EXISTS idx_character_votes_tmdb_id ON public.character_votes(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_fav_actor_votes_user ON public.favorite_actor_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_fav_actor_votes_tmdb ON public.favorite_actor_votes(tmdb_id, media_type);

-- ============================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watch_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_list_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.character_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_actor_votes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. RLS POLICIES
-- ============================================================

-- Profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Watchlist
DROP POLICY IF EXISTS "Users can view their own watchlist" ON public.watchlist;
CREATE POLICY "Users can view their own watchlist" ON public.watchlist FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert to their watchlist" ON public.watchlist;
CREATE POLICY "Users can insert to their watchlist" ON public.watchlist FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their watchlist" ON public.watchlist;
CREATE POLICY "Users can update their watchlist" ON public.watchlist FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete from their watchlist" ON public.watchlist;
CREATE POLICY "Users can delete from their watchlist" ON public.watchlist FOR DELETE USING (auth.uid() = user_id);

-- Watch History
DROP POLICY IF EXISTS "Users can view their own watch history" ON public.watch_history;
CREATE POLICY "Users can view their own watch history" ON public.watch_history FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert to their watch history" ON public.watch_history;
CREATE POLICY "Users can insert to their watch history" ON public.watch_history FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their watch history" ON public.watch_history;
CREATE POLICY "Users can update their watch history" ON public.watch_history FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete from their watch history" ON public.watch_history;
CREATE POLICY "Users can delete from their watch history" ON public.watch_history FOR DELETE USING (auth.uid() = user_id);

-- Favorites
DROP POLICY IF EXISTS "Users can view their own favorites" ON public.favorites;
CREATE POLICY "Users can view their own favorites" ON public.favorites FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert to their favorites" ON public.favorites;
CREATE POLICY "Users can insert to their favorites" ON public.favorites FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete from their favorites" ON public.favorites;
CREATE POLICY "Users can delete from their favorites" ON public.favorites FOR DELETE USING (auth.uid() = user_id);

-- Comments
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON public.comments;
CREATE POLICY "Comments are viewable by everyone" ON public.comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert comments" ON public.comments;
CREATE POLICY "Users can insert comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;
CREATE POLICY "Users can delete their own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- Comment Likes
DROP POLICY IF EXISTS "Comment likes are viewable by everyone" ON public.comment_likes;
CREATE POLICY "Comment likes are viewable by everyone" ON public.comment_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can like comments" ON public.comment_likes;
CREATE POLICY "Users can like comments" ON public.comment_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike comments" ON public.comment_likes;
CREATE POLICY "Users can unlike comments" ON public.comment_likes FOR DELETE USING (auth.uid() = user_id);

-- Follows
DROP POLICY IF EXISTS "Follows are viewable by everyone" ON public.follows;
CREATE POLICY "Follows are viewable by everyone" ON public.follows FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can follow others" ON public.follows;
CREATE POLICY "Users can follow others" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can unfollow others" ON public.follows;
CREATE POLICY "Users can unfollow others" ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- Reactions
DROP POLICY IF EXISTS "Reactions are viewable by everyone" ON public.reactions;
CREATE POLICY "Reactions are viewable by everyone" ON public.reactions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can add reactions" ON public.reactions;
CREATE POLICY "Users can add reactions" ON public.reactions FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their reactions" ON public.reactions;
CREATE POLICY "Users can update their reactions" ON public.reactions FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their reactions" ON public.reactions;
CREATE POLICY "Users can delete their reactions" ON public.reactions FOR DELETE USING (auth.uid() = user_id);

-- Notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON public.notifications;
CREATE POLICY "Authenticated users can insert notifications" ON public.notifications FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Custom Lists
DROP POLICY IF EXISTS "Public lists are viewable by everyone" ON public.custom_lists;
CREATE POLICY "Public lists are viewable by everyone" ON public.custom_lists FOR SELECT USING (is_public = true OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create lists" ON public.custom_lists;
CREATE POLICY "Users can create lists" ON public.custom_lists FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own lists" ON public.custom_lists;
CREATE POLICY "Users can update their own lists" ON public.custom_lists FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own lists" ON public.custom_lists;
CREATE POLICY "Users can delete their own lists" ON public.custom_lists FOR DELETE USING (auth.uid() = user_id);

-- Custom List Items
DROP POLICY IF EXISTS "List items viewable if list is viewable" ON public.custom_list_items;
CREATE POLICY "List items viewable if list is viewable" ON public.custom_list_items FOR SELECT 
  USING (EXISTS (SELECT 1 FROM public.custom_lists WHERE id = list_id AND (is_public = true OR user_id = auth.uid())));

DROP POLICY IF EXISTS "Users can add items to their lists" ON public.custom_list_items;
CREATE POLICY "Users can add items to their lists" ON public.custom_list_items FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM public.custom_lists WHERE id = list_id AND user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can remove items from their lists" ON public.custom_list_items;
CREATE POLICY "Users can remove items from their lists" ON public.custom_list_items FOR DELETE 
  USING (EXISTS (SELECT 1 FROM public.custom_lists WHERE id = list_id AND user_id = auth.uid()));

-- Ratings
DROP POLICY IF EXISTS "Ratings are viewable by everyone" ON public.ratings;
CREATE POLICY "Ratings are viewable by everyone" ON public.ratings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own ratings" ON public.ratings;
CREATE POLICY "Users can insert their own ratings" ON public.ratings FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own ratings" ON public.ratings;
CREATE POLICY "Users can update their own ratings" ON public.ratings FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own ratings" ON public.ratings;
CREATE POLICY "Users can delete their own ratings" ON public.ratings FOR DELETE USING (auth.uid() = user_id);

-- Shared Lists
DROP POLICY IF EXISTS "Members can view shared lists" ON public.shared_lists;
CREATE POLICY "Members can view shared lists" ON public.shared_lists FOR SELECT USING (
  auth.uid() = creator_id OR EXISTS (
    SELECT 1 FROM public.shared_list_members WHERE list_id = id AND user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can create shared lists" ON public.shared_lists;
CREATE POLICY "Users can create shared lists" ON public.shared_lists FOR INSERT WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can update shared lists" ON public.shared_lists;
CREATE POLICY "Creators can update shared lists" ON public.shared_lists FOR UPDATE USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can delete shared lists" ON public.shared_lists;
CREATE POLICY "Creators can delete shared lists" ON public.shared_lists FOR DELETE USING (auth.uid() = creator_id);

-- Shared List Members
DROP POLICY IF EXISTS "Members can view members" ON public.shared_list_members;
CREATE POLICY "Members can view members" ON public.shared_list_members FOR SELECT 
  USING (EXISTS (SELECT 1 FROM public.shared_list_members slm WHERE slm.list_id = shared_list_members.list_id AND slm.user_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can add members" ON public.shared_list_members;
CREATE POLICY "Admins can add members" ON public.shared_list_members FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM public.shared_lists WHERE id = list_id AND creator_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can remove members" ON public.shared_list_members;
CREATE POLICY "Admins can remove members" ON public.shared_list_members FOR DELETE 
  USING (EXISTS (SELECT 1 FROM public.shared_lists WHERE id = list_id AND creator_id = auth.uid()));

-- Shared List Items
DROP POLICY IF EXISTS "Members can view items" ON public.shared_list_items;
CREATE POLICY "Members can view items" ON public.shared_list_items FOR SELECT 
  USING (EXISTS (SELECT 1 FROM public.shared_list_members WHERE list_id = shared_list_items.list_id AND user_id = auth.uid()));

DROP POLICY IF EXISTS "Members can add items" ON public.shared_list_items;
CREATE POLICY "Members can add items" ON public.shared_list_items FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM public.shared_list_members WHERE list_id = shared_list_items.list_id AND user_id = auth.uid()));

DROP POLICY IF EXISTS "Members can remove items" ON public.shared_list_items;
CREATE POLICY "Members can remove items" ON public.shared_list_items FOR DELETE 
  USING (EXISTS (SELECT 1 FROM public.shared_list_members WHERE list_id = shared_list_items.list_id AND user_id = auth.uid()));

-- Character Votes
DROP POLICY IF EXISTS "Users can view all character votes" ON public.character_votes;
CREATE POLICY "Users can view all character votes" ON public.character_votes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own votes" ON public.character_votes;
CREATE POLICY "Users can insert their own votes" ON public.character_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own votes" ON public.character_votes;
CREATE POLICY "Users can update their own votes" ON public.character_votes FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own votes" ON public.character_votes;
CREATE POLICY "Users can delete their own votes" ON public.character_votes FOR DELETE USING (auth.uid() = user_id);

-- Favorite Actor Votes
DROP POLICY IF EXISTS "Anyone can view favorite actor votes" ON public.favorite_actor_votes;
CREATE POLICY "Anyone can view favorite actor votes" ON public.favorite_actor_votes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own votes" ON public.favorite_actor_votes;
CREATE POLICY "Users can insert their own votes" ON public.favorite_actor_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own votes" ON public.favorite_actor_votes;
CREATE POLICY "Users can delete their own votes" ON public.favorite_actor_votes FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- 6. GRANTS
-- ============================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

GRANT ALL ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO anon;

GRANT ALL ON public.watchlist TO authenticated;
GRANT ALL ON public.watch_history TO authenticated;
GRANT ALL ON public.favorites TO authenticated;

GRANT ALL ON public.comments TO authenticated;
GRANT SELECT ON public.comments TO anon;

GRANT ALL ON public.comment_likes TO authenticated;
GRANT SELECT ON public.comment_likes TO anon;

GRANT ALL ON public.follows TO authenticated;
GRANT SELECT ON public.follows TO anon;

GRANT ALL ON public.reactions TO authenticated;
GRANT SELECT ON public.reactions TO anon;

GRANT ALL ON public.notifications TO authenticated;

GRANT ALL ON public.custom_lists TO authenticated;
GRANT ALL ON public.custom_list_items TO authenticated;

GRANT ALL ON public.ratings TO authenticated;
GRANT SELECT ON public.ratings TO anon;

GRANT ALL ON public.shared_lists TO authenticated;
GRANT ALL ON public.shared_list_members TO authenticated;
GRANT ALL ON public.shared_list_items TO authenticated;

GRANT ALL ON public.character_votes TO authenticated;
GRANT SELECT ON public.character_votes TO anon;

GRANT ALL ON public.favorite_actor_votes TO authenticated;
GRANT SELECT ON public.favorite_actor_votes TO anon;

-- ============================================================
-- 7. TRIGGER: Auto-create profile on signup
-- ============================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter INTEGER := 0;
BEGIN
  base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    split_part(NEW.email, '@', 1)
  );
  final_username := base_username;
  
  LOOP
    BEGIN
      INSERT INTO public.profiles (id, username)
      VALUES (NEW.id, final_username);
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      counter := counter + 1;
      final_username := base_username || '_' || counter::TEXT;
      IF counter > 100 THEN
        final_username := base_username || '_' || extract(epoch from now())::TEXT;
        INSERT INTO public.profiles (id, username) VALUES (NEW.id, final_username);
        EXIT;
      END IF;
    END;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 8. TRIGGER: Auto-update updated_at timestamp
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_custom_lists_updated_at ON public.custom_lists;
CREATE TRIGGER update_custom_lists_updated_at
  BEFORE UPDATE ON public.custom_lists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_shared_lists_updated_at ON public.shared_lists;
CREATE TRIGGER update_shared_lists_updated_at
  BEFORE UPDATE ON public.shared_lists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 9. VIEW: comments_with_likes
-- ============================================================

DROP VIEW IF EXISTS public.comments_with_likes;
CREATE OR REPLACE VIEW public.comments_with_likes
  WITH (security_invoker = true)
AS
  SELECT c.*, COUNT(cl.id) AS likes_count
  FROM public.comments c
  LEFT JOIN public.comment_likes cl ON cl.comment_id = c.id
  GROUP BY c.id;

-- ============================================================
-- 10. RPC: get_average_rating (show/movie level only)
-- ============================================================

CREATE OR REPLACE FUNCTION get_average_rating(p_tmdb_id INTEGER, p_media_type TEXT)
RETURNS NUMERIC AS $$
  SELECT COALESCE(AVG(rating), 0) FROM public.ratings 
  WHERE tmdb_id = p_tmdb_id 
    AND media_type = p_media_type
    AND season_number IS NULL 
    AND episode_number IS NULL;
$$ LANGUAGE sql STABLE;

-- ============================================================
-- 11. RPC: get_episode_average_rating
-- ============================================================

CREATE OR REPLACE FUNCTION get_episode_average_rating(
  p_tmdb_id INTEGER, 
  p_season_number INTEGER, 
  p_episode_number INTEGER
)
RETURNS NUMERIC AS $$
  SELECT COALESCE(AVG(rating), 0) FROM public.ratings 
  WHERE tmdb_id = p_tmdb_id 
    AND media_type = 'tv'
    AND season_number = p_season_number 
    AND episode_number = p_episode_number;
$$ LANGUAGE sql STABLE;

-- ============================================================
-- 12. RPC: get_following_watch_hours
-- ============================================================

CREATE OR REPLACE FUNCTION get_following_watch_hours(p_user_id UUID)
RETURNS TABLE(user_id UUID, username TEXT, avatar_url TEXT, total_hours NUMERIC, is_me BOOLEAN) AS $$
  SELECT result_user_id, result_username, result_avatar_url, result_hours, result_is_me FROM (
    SELECT f.following_id AS result_user_id, p.username AS result_username, p.avatar_url AS result_avatar_url,
      COALESCE(SUM(CASE WHEN wh.media_type = 'tv' THEN 45 ELSE 120 END), 0) / 60.0 AS result_hours,
      FALSE AS result_is_me
    FROM public.follows f JOIN public.profiles p ON p.id = f.following_id
    LEFT JOIN public.watch_history wh ON wh.user_id = f.following_id
    WHERE f.follower_id = p_user_id
    GROUP BY f.following_id, p.username, p.avatar_url
    UNION ALL
    SELECT p.id AS result_user_id, p.username AS result_username, p.avatar_url AS result_avatar_url,
      COALESCE(SUM(CASE WHEN wh.media_type = 'tv' THEN 45 ELSE 120 END), 0) / 60.0 AS result_hours,
      TRUE AS result_is_me
    FROM public.profiles p LEFT JOIN public.watch_history wh ON wh.user_id = p.id
    WHERE p.id = p_user_id GROUP BY p.id, p.username, p.avatar_url
  ) sub
  ORDER BY result_hours DESC;
$$ LANGUAGE sql STABLE;

-- ============================================================
-- DONE
-- ============================================================
