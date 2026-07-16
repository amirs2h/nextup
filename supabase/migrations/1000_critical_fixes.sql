-- Migration 1000: Critical fixes for data integrity and security

-- ============================================================
-- 1. FIX watch_history UNIQUE constraint
-- ============================================================
-- The COALESCE expression index (from migration 021/999) doesn't work
-- with Supabase upsert onConflict (which expects column names, not expressions).
-- Solution: use a plain UNIQUE constraint + normalize NULLs in Dart code.
-- For movies (season_number=NULL, episode_number=NULL), the Dart code will
-- use 0 instead of NULL so the constraint catches duplicates.

-- Drop any existing indexes/constraints first (idempotent)
ALTER TABLE watch_history DROP CONSTRAINT IF EXISTS watch_history_unique_key;
ALTER TABLE watch_history DROP CONSTRAINT IF EXISTS watch_history_unique;
DROP INDEX IF EXISTS watch_history_unique_idx;
DROP INDEX IF EXISTS watch_history_unique_key;
DROP INDEX IF EXISTS watch_history_user_episode_unique;

-- Create plain UNIQUE constraint (works with Supabase upsert onConflict)
ALTER TABLE watch_history 
  ADD CONSTRAINT watch_history_unique_key 
  UNIQUE (user_id, tmdb_id, media_type, season_number, episode_number);

-- ============================================================
-- 2. FIX notification INSERT policy (spoofing vulnerability)
-- ============================================================
-- The old policy allowed ANY authenticated user to insert
-- notifications addressed to ANY user_id. Restrict to own user.
DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON notifications;
CREATE POLICY "Users can insert own notifications" ON notifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);
