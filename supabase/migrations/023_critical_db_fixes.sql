-- Phase 1: Critical database fixes

-- 1. Missing GRANTs for authenticated role
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON custom_lists TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON custom_list_items TO authenticated;

-- 2. Drop conflicting ratings constraint (from migration 009)
-- The expression index from migration 021 is the correct one
ALTER TABLE ratings DROP CONSTRAINT IF EXISTS ratings_user_episode_unique;

-- 3. Fix addToWatchlist - ensure unique constraint exists for onConflict
-- The constraint already exists from migration 001: UNIQUE(user_id, tmdb_id, media_type, list_name)
-- No additional SQL needed - just need Dart fix
