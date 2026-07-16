-- Migration 1000: Critical fixes for data integrity and security

-- ============================================================
-- 1. FIX watch_history UNIQUE constraint (NULL-inequality bug)
-- ============================================================
-- Migration 021 created a COALESCE expression index that treated
-- NULL season/episode as 0. Migrations 025/999 reverted to a plain
-- constraint, reintroducing the bug: two rows with
-- (season_number=NULL, episode_number=NULL) for the same movie
-- bypass the UNIQUE constraint (NULL != NULL in Postgres).
-- Fix: restore the COALESCE expression index.

-- Drop the plain constraint that doesn't handle NULLs
ALTER TABLE watch_history DROP CONSTRAINT IF EXISTS watch_history_unique_key;
-- Drop the expression index if it exists (idempotent)
DROP INDEX IF EXISTS watch_history_unique_idx;
DROP INDEX IF EXISTS watch_history_user_episode_unique;
-- Create the expression index that correctly handles NULLs
CREATE UNIQUE INDEX watch_history_unique_idx ON watch_history
  (user_id, tmdb_id, media_type, COALESCE(season_number, 0), COALESCE(episode_number, 0));

-- ============================================================
-- 2. FIX notification INSERT policy (spoofing vulnerability)
-- ============================================================
-- The old policy allowed ANY authenticated user to insert
-- notifications addressed to ANY user_id. Restrict to own user.
DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON notifications;
CREATE POLICY "Users can insert own notifications" ON notifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);
