-- Fix Episode Rating UNIQUE Constraint
-- Run this in Supabase SQL Editor

-- Remove old constraint
ALTER TABLE ratings DROP CONSTRAINT IF EXISTS ratings_user_id_tmdb_id_media_type_key;

-- Add new constraint with episode support
ALTER TABLE ratings ADD CONSTRAINT ratings_user_episode_unique 
UNIQUE(user_id, tmdb_id, media_type, season_number, episode_number);
