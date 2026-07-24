-- ============================================================
-- MIGRATION 1018: Fix ranking to return INTEGER hours
-- ============================================================

-- ۱. Drop old versions first (return type changed from NUMERIC to INTEGER)
DROP FUNCTION IF EXISTS get_following_watch_hours(UUID);
DROP FUNCTION IF EXISTS get_user_stats(UUID);

-- ۲. Ranking: returns INTEGER hours (no decimals)
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
    FROM public.follows f
    JOIN public.profiles p ON p.id = f.following_id
    LEFT JOIN public.watch_history wh ON wh.user_id = f.following_id
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
    FROM public.profiles p
    LEFT JOIN public.watch_history wh ON wh.user_id = p.id
    WHERE p.id = p_user_id
    GROUP BY p.id, p.username, p.avatar_url
  ) sub
  ORDER BY result_hours DESC;
$$ LANGUAGE sql STABLE;

-- ۳. Stats: also INTEGER hours, aligned with ranking
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
$$ LANGUAGE sql STABLE;

-- ۴. Fix remaining NULL/0 runtime
UPDATE public.watch_history
SET runtime_minutes = CASE WHEN media_type = 'tv' THEN 45 ELSE 120 END
WHERE runtime_minutes IS NULL OR runtime_minutes = 0;

NOTIFY pgrst, 'reload schema';
