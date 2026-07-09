-- Fix get_average_rating to only include show/movie level ratings
-- Currently it mixes show ratings with episode ratings

CREATE OR REPLACE FUNCTION get_average_rating(p_tmdb_id INTEGER, p_media_type TEXT)
RETURNS NUMERIC AS $$
  SELECT COALESCE(AVG(rating), 0) FROM ratings 
  WHERE tmdb_id = p_tmdb_id 
    AND media_type = p_media_type
    AND season_number IS NULL 
    AND episode_number IS NULL;
$$ LANGUAGE sql STABLE;

-- Also create a function for episode-specific ratings
CREATE OR REPLACE FUNCTION get_episode_average_rating(
  p_tmdb_id INTEGER, 
  p_season_number INTEGER, 
  p_episode_number INTEGER
)
RETURNS NUMERIC AS $$
  SELECT COALESCE(AVG(rating), 0) FROM ratings 
  WHERE tmdb_id = p_tmdb_id 
    AND media_type = 'tv'
    AND season_number = p_season_number 
    AND episode_number = p_episode_number;
$$ LANGUAGE sql STABLE;
