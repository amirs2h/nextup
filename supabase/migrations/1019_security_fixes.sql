-- ============================================================
-- MIGRATION 1019: Security fixes - search_path + REVOKE EXECUTE
-- ============================================================

-- 1. Revoke EXECUTE on recalc_user_xp from anon and authenticated
--    (should only be called by trigger, not via REST API)
REVOKE EXECUTE ON FUNCTION recalc_user_xp(UUID) FROM anon, authenticated;

-- 2. Revoke EXECUTE on trigger function from anon and authenticated
REVOKE EXECUTE ON FUNCTION trg_user_achievements_recalc() FROM anon, authenticated;

-- 3. Fix search_path on get_user_stats (recreate with SET search_path)
DROP FUNCTION IF EXISTS get_user_stats(UUID);
CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS TABLE(
  total_shows BIGINT,
  total_movies BIGINT,
  total_episodes BIGINT,
  total_hours INTEGER
) AS $$
  SELECT
    COUNT(DISTINCT CASE
      WHEN wh.media_type = 'tv'
        AND wh.episode_number IS NOT NULL
        AND wh.episode_number > 0
      THEN wh.tmdb_id
    END)::BIGINT as total_shows,
    COUNT(DISTINCT CASE WHEN wh.media_type = 'movie' THEN wh.tmdb_id END)::BIGINT as total_movies,
    COUNT(CASE
      WHEN wh.media_type = 'tv'
        AND wh.episode_number IS NOT NULL
        AND wh.episode_number > 0
      THEN 1
    END)::BIGINT as total_episodes,
    FLOOR(COALESCE(SUM(
      CASE
        WHEN wh.media_type = 'tv' AND wh.episode_number IS NOT NULL AND wh.episode_number > 0 THEN
          COALESCE(wh.runtime_minutes, 45)
        WHEN wh.media_type = 'movie' THEN
          COALESCE(wh.runtime_minutes, 120)
        ELSE 0
      END
    ), 0) / 60.0)::INTEGER as total_hours
  FROM watch_history wh
  WHERE wh.user_id = target_user_id;
$$ LANGUAGE sql STABLE SET search_path = public;

-- 4. Fix search_path on get_common_content
DROP FUNCTION IF EXISTS get_common_content(UUID, UUID);
CREATE OR REPLACE FUNCTION get_common_content(user_a UUID, user_b UUID)
RETURNS TABLE(
  tmdb_id INTEGER,
  media_type TEXT,
  title TEXT,
  poster_path TEXT
) AS $$
  SELECT DISTINCT
    wh.tmdb_id,
    wh.media_type,
    COALESCE(wh.title, 'Unknown') as title,
    wh.poster_path
  FROM watch_history wh
  WHERE wh.user_id = user_a
    AND (
      (wh.media_type = 'tv' AND wh.episode_number IS NOT NULL AND wh.episode_number > 0)
      OR wh.media_type = 'movie'
    )
    AND EXISTS (
      SELECT 1 FROM watch_history wh2
      WHERE wh2.user_id = user_b
        AND wh2.tmdb_id = wh.tmdb_id
        AND wh2.media_type = wh.media_type
        AND (
          (wh2.media_type = 'tv' AND wh2.episode_number IS NOT NULL AND wh2.episode_number > 0)
          OR wh2.media_type = 'movie'
        )
    )
  ORDER BY wh.tmdb_id;
$$ LANGUAGE sql STABLE SET search_path = public;

-- 5. Fix search_path on get_following_watch_hours
DROP FUNCTION IF EXISTS get_following_watch_hours(UUID);
CREATE OR REPLACE FUNCTION get_following_watch_hours(p_user_id UUID)
RETURNS TABLE(
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  total_hours INTEGER,
  is_me BOOLEAN
) AS $$
  SELECT result_user_id, result_username, result_avatar_url, result_hours, result_is_me FROM (
    SELECT
      f.following_id AS result_user_id,
      p.username AS result_username,
      p.avatar_url AS result_avatar_url,
      FLOOR(COALESCE(SUM(
        CASE
          WHEN wh.media_type = 'tv' AND wh.episode_number IS NOT NULL AND wh.episode_number > 0 THEN
            COALESCE(wh.runtime_minutes, 45)
          WHEN wh.media_type = 'movie' THEN
            COALESCE(wh.runtime_minutes, 120)
          ELSE 0
        END
      ), 0) / 60.0)::INTEGER AS result_hours,
      FALSE AS result_is_me
    FROM follows f
    JOIN profiles p ON p.id = f.following_id
    LEFT JOIN watch_history wh ON wh.user_id = f.following_id
    WHERE f.follower_id = p_user_id
    GROUP BY f.following_id, p.username, p.avatar_url
    UNION ALL
    SELECT
      p.id AS result_user_id,
      p.username AS result_username,
      p.avatar_url AS result_avatar_url,
      FLOOR(COALESCE(SUM(
        CASE
          WHEN wh.media_type = 'tv' AND wh.episode_number IS NOT NULL AND wh.episode_number > 0 THEN
            COALESCE(wh.runtime_minutes, 45)
          WHEN wh.media_type = 'movie' THEN
            COALESCE(wh.runtime_minutes, 120)
          ELSE 0
        END
      ), 0) / 60.0)::INTEGER AS result_hours,
      TRUE AS result_is_me
    FROM profiles p
    LEFT JOIN watch_history wh ON wh.user_id = p.id
    WHERE p.id = p_user_id
    GROUP BY p.id, p.username, p.avatar_url
  ) sub
  ORDER BY result_hours DESC;
$$ LANGUAGE sql STABLE SET search_path = public;

NOTIFY pgrst, 'reload schema';
