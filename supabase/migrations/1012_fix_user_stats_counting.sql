-- ============================================================
-- MIGRATION 1012: Align get_user_stats episode counting with app
-- Episodes = TV rows with episode_number IS NOT NULL AND > 0
-- Hours = (episodes * 45 + movies * 120) / 60
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS TABLE(
  total_shows BIGINT,
  total_movies BIGINT,
  total_episodes BIGINT,
  total_hours NUMERIC
) AS $$
  SELECT
    COUNT(DISTINCT CASE WHEN wh.media_type = 'tv' THEN wh.tmdb_id END)::BIGINT as total_shows,
    COUNT(DISTINCT CASE WHEN wh.media_type = 'movie' THEN wh.tmdb_id END)::BIGINT as total_movies,
    COUNT(CASE
      WHEN wh.media_type = 'tv'
        AND wh.episode_number IS NOT NULL
        AND wh.episode_number > 0
      THEN 1
    END)::BIGINT as total_episodes,
    (
      COUNT(CASE
        WHEN wh.media_type = 'tv'
          AND wh.episode_number IS NOT NULL
          AND wh.episode_number > 0
        THEN 1
      END) * 45
      + COUNT(DISTINCT CASE WHEN wh.media_type = 'movie' THEN wh.tmdb_id END) * 120
    ) / 60.0 as total_hours
  FROM watch_history wh
  WHERE wh.user_id = target_user_id;
$$ LANGUAGE sql STABLE;

NOTIFY pgrst, 'reload schema';
