-- Migration 023: Fix missing GRANTs and conflicting constraints
-- Production-grade, idempotent migration

-- 1. GRANT for notifications table (was never granted)
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;

-- 2. GRANT for custom_lists table (was never granted)
GRANT SELECT, INSERT, UPDATE, DELETE ON custom_lists TO authenticated;

-- 3. GRANT for custom_list_items table (was never granted)
GRANT SELECT, INSERT, UPDATE, DELETE ON custom_list_items TO authenticated;

-- 4. GRANT SELECT to anon role for publicly-readable tables
GRANT SELECT ON profiles TO anon;
GRANT SELECT ON comments TO anon;
GRANT SELECT ON comment_likes TO anon;
GRANT SELECT ON follows TO anon;
GRANT SELECT ON reactions TO anon;
GRANT SELECT ON ratings TO anon;
GRANT SELECT ON favorite_actor_votes TO anon;
GRANT SELECT ON character_votes TO anon;

-- 5. Drop conflicting unique constraint on ratings table
-- Migration 009 added this constraint which conflicts with the expression index from migration 015
ALTER TABLE ratings DROP CONSTRAINT IF EXISTS ratings_user_episode_unique;

-- 6. Verify the expression index exists (recreate if needed)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'ratings_unique_user_media_episode'
  ) THEN
    CREATE UNIQUE INDEX ratings_unique_user_media_episode
      ON ratings (user_id, tmdb_id, media_type, COALESCE(season_number, 0), COALESCE(episode_number, 0));
  END IF;
END $$;
