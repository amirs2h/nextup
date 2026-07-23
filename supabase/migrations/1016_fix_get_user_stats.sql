-- ============================================================
-- MIGRATION 1016: Fix get_user_stats — align with all other paths
-- Filter TV hours by episode_number > 0; use runtime_minutes with COALESCE
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS TABLE(
  total_shows BIGINT,
  total_movies BIGINT,
  total_episodes BIGINT,
  total_hours NUMERIC
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
    COALESCE(SUM(
      CASE
        WHEN wh.media_type = 'tv' AND wh.episode_number IS NOT NULL AND wh.episode_number > 0 THEN
          COALESCE(wh.runtime_minutes, 45)
        WHEN wh.media_type = 'movie' THEN
          COALESCE(wh.runtime_minutes, 120)
        ELSE 0
      END
    ), 0) / 60.0 as total_hours
  FROM watch_history wh
  WHERE wh.user_id = target_user_id;
$$ LANGUAGE sql STABLE;

NOTIFY pgrst, 'reload schema';
