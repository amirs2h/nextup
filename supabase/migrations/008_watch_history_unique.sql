-- Add UNIQUE constraint to watch_history to prevent duplicates
-- Run this in Supabase SQL Editor

-- First, remove any existing duplicates
DELETE FROM watch_history a USING watch_history b
WHERE a.id > b.id 
  AND a.user_id = b.user_id 
  AND a.tmdb_id = b.tmdb_id 
  AND a.media_type = b.media_type 
  AND COALESCE(a.season_number, 0) = COALESCE(b.season_number, 0)
  AND COALESCE(a.episode_number, 0) = COALESCE(b.episode_number, 0);

-- Add unique constraint
ALTER TABLE watch_history 
ADD CONSTRAINT watch_history_unique 
UNIQUE (user_id, tmdb_id, media_type, season_number, episode_number);
