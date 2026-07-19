-- ============================================================
-- MIGRATION 1005: Stats comparison & common content
-- ============================================================

-- 1. RPC function to get common watched content between two users
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
    AND EXISTS (
      SELECT 1 FROM watch_history wh2 
      WHERE wh2.user_id = user_b 
        AND wh2.tmdb_id = wh.tmdb_id 
        AND wh2.media_type = wh.media_type
    )
  ORDER BY wh.tmdb_id;
$$ LANGUAGE sql STABLE;

-- 2. RPC function to get user stats summary
CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS TABLE(
  total_shows BIGINT,
  total_movies BIGINT,
  total_episodes BIGINT,
  total_hours NUMERIC
) AS $$
  SELECT
    COUNT(DISTINCT CASE WHEN wh.media_type = 'tv' THEN wh.tmdb_id END) as total_shows,
    COUNT(DISTINCT CASE WHEN wh.media_type = 'movie' THEN wh.tmdb_id END) as total_movies,
    COUNT(CASE WHEN wh.media_type = 'tv' THEN 1 END) as total_episodes,
    COALESCE(SUM(CASE WHEN wh.media_type = 'tv' THEN 45 ELSE 120 END), 0) / 60.0 as total_hours
  FROM watch_history wh
  WHERE wh.user_id = target_user_id;
$$ LANGUAGE sql STABLE;
