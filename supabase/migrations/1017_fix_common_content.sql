-- ============================================================
-- MIGRATION 1017: Fix get_common_content — filter TV by episode_number > 0
-- Prevents false matches from invalid TV rows
-- ============================================================

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
$$ LANGUAGE sql STABLE;

NOTIFY pgrst, 'reload schema';
