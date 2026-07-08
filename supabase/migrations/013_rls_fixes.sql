-- Migration 013: Fix RLS policies for watchlist, favorites, watch_history
-- 1. Add is_public column to profiles FIRST
-- 2. Add UPDATE policy on watchlist (needed for status changes)
-- 3. Add public read policies so users can see each other's profiles

-- Step 1: Add is_public column to profiles (must be first!)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true;

-- Step 2: Watchlist: Add UPDATE policy for owner
CREATE POLICY "Users can update their own watchlist" ON watchlist
  FOR UPDATE USING (auth.uid() = user_id);

-- Step 3: Watchlist: Allow public read (for profile visibility)
DROP POLICY IF EXISTS "Users can view their own watchlist" ON watchlist;
CREATE POLICY "Users can view watchlist" ON watchlist
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = watchlist.user_id
      AND profiles.is_public = true
    )
  );

-- Step 4: Favorites: Allow public read (for profile visibility)
DROP POLICY IF EXISTS "Users can view their own favorites" ON favorites;
CREATE POLICY "Users can view favorites" ON favorites
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = favorites.user_id
      AND profiles.is_public = true
    )
  );

-- Step 5: Watch History: Allow public read (for activity feed and profile)
DROP POLICY IF EXISTS "Users can view their own watch_history" ON watch_history;
CREATE POLICY "Users can view watch_history" ON watch_history
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = watch_history.user_id
      AND profiles.is_public = true
    )
  );
