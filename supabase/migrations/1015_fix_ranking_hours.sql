-- ============================================================
-- MIGRATION 1015: Fix get_following_watch_hours
-- Align with get_user_stats: runtime_minutes + episode_number > 0
-- ============================================================

CREATE OR REPLACE FUNCTION get_following_watch_hours(p_user_id UUID)
RETURNS TABLE(
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  total_hours NUMERIC,
  is_me BOOLEAN
) AS $$
  SELECT result_user_id, result_username, result_avatar_url, result_hours, result_is_me FROM (
    SELECT
      f.following_id AS result_user_id,
      p.username AS result_username,
      p.avatar_url AS result_avatar_url,
      COALESCE(SUM(
        CASE
          WHEN wh.media_type = 'tv' AND wh.episode_number IS NOT NULL AND wh.episode_number > 0 THEN
            COALESCE(wh.runtime_minutes, 45)
          WHEN wh.media_type = 'movie' THEN
            COALESCE(wh.runtime_minutes, 120)
          ELSE 0
        END
      ), 0) / 60.0 AS result_hours,
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
      COALESCE(SUM(
        CASE
          WHEN wh.media_type = 'tv' AND wh.episode_number IS NOT NULL AND wh.episode_number > 0 THEN
            COALESCE(wh.runtime_minutes, 45)
          WHEN wh.media_type = 'movie' THEN
            COALESCE(wh.runtime_minutes, 120)
          ELSE 0
        END
      ), 0) / 60.0 AS result_hours,
      TRUE AS result_is_me
    FROM public.profiles p
    LEFT JOIN public.watch_history wh ON wh.user_id = p.id
    WHERE p.id = p_user_id
    GROUP BY p.id, p.username, p.avatar_url
  ) sub
  ORDER BY result_hours DESC;
$$ LANGUAGE sql STABLE;

NOTIFY pgrst, 'reload schema';
