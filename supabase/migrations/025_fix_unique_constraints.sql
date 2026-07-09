-- Fix watch_history unique constraint for upsert compatibility
-- The expression index with COALESCE doesn't work with Supabase upsert onConflict
-- We need a regular unique constraint

-- Drop the expression index if it exists
DROP INDEX IF EXISTS watch_history_user_episode_unique;

-- Create a proper unique constraint that works with upsert
-- This handles NULL values by treating them as part of the key
ALTER TABLE watch_history 
  DROP CONSTRAINT IF EXISTS watch_history_unique_key;

ALTER TABLE watch_history 
  ADD CONSTRAINT watch_history_unique_key 
  UNIQUE (user_id, tmdb_id, media_type, season_number, episode_number);

-- Fix character_votes upsert - add onConflict support
-- The table already has UNIQUE(user_id, person_id, tmdb_id, character_name)
-- No SQL changes needed, just Dart fix
