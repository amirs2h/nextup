-- Migration 015: Complete fix for all remaining issues
-- Run this ONCE in Supabase SQL Editor

-- ============================================================
-- 1. FIX RATINGS TABLE
-- ============================================================

-- Add missing columns
ALTER TABLE ratings ADD COLUMN IF NOT EXISTS season_number INTEGER;
ALTER TABLE ratings ADD COLUMN IF NOT EXISTS episode_number INTEGER;

-- Add CHECK constraint on rating range (0-10)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'ratings_rating_check'
  ) THEN
    ALTER TABLE ratings ADD CONSTRAINT ratings_rating_check CHECK (rating >= 0 AND rating <= 10);
  END IF;
END $$;

-- Add CHECK constraint on media_type
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'ratings_media_type_check'
  ) THEN
    ALTER TABLE ratings ADD CONSTRAINT ratings_media_type_check CHECK (media_type IN ('tv', 'movie'));
  END IF;
END $$;

-- Drop old UNIQUE constraints
ALTER TABLE ratings DROP CONSTRAINT IF EXISTS ratings_user_id_tmdb_id_key;
ALTER TABLE ratings DROP CONSTRAINT IF EXISTS ratings_user_id_tmdb_id_media_type_key;
ALTER TABLE ratings DROP CONSTRAINT IF EXISTS ratings_unique_user_media;
ALTER TABLE ratings DROP CONSTRAINT IF EXISTS ratings_unique_user_media_season_episode;

-- Create unique index instead of UNIQUE constraint with expressions
CREATE UNIQUE INDEX IF NOT EXISTS ratings_unique_user_media_episode
  ON ratings (user_id, tmdb_id, media_type, COALESCE(season_number, 0), COALESCE(episode_number, 0));

-- ============================================================
-- 2. CREATE CHARACTER_VOTES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS character_votes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  person_id INTEGER NOT NULL,
  tmdb_id INTEGER NOT NULL,
  character_name TEXT NOT NULL,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('up', 'down')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, person_id, tmdb_id, character_name)
);

-- ============================================================
-- 3. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_ratings_tmdb_media ON ratings(tmdb_id, media_type);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_reactions_tmdb_season_episode ON reactions(tmdb_id, season_number, episode_number);
CREATE INDEX IF NOT EXISTS idx_custom_lists_user_id ON custom_lists(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_lists_creator_id ON shared_lists(creator_id);
CREATE INDEX IF NOT EXISTS idx_character_votes_user_id ON character_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_character_votes_person_id ON character_votes(person_id);
CREATE INDEX IF NOT EXISTS idx_character_votes_tmdb_id ON character_votes(tmdb_id);

-- ============================================================
-- 4. RLS POLICY FIXES
-- ============================================================

-- Fix profiles INSERT policy
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Add reactions DELETE policy
DROP POLICY IF EXISTS "Users can delete their own reactions" ON reactions;
CREATE POLICY "Users can delete their own reactions" ON reactions
  FOR DELETE USING (auth.uid() = user_id);

-- Fix shared_lists SELECT policy to include creator
DROP POLICY IF EXISTS "Members can view shared lists" ON shared_lists;
CREATE POLICY "Members can view shared lists" ON shared_lists
  FOR SELECT USING (
    auth.uid() = creator_id OR EXISTS (
      SELECT 1 FROM shared_list_members
      WHERE list_id = id AND user_id = auth.uid()
    )
  );

-- Fix notifications INSERT policy
DROP POLICY IF EXISTS "Users can insert their own notifications" ON notifications;
DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON notifications;
CREATE POLICY "Authenticated users can insert notifications" ON notifications
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- 5. CHARACTER_VOTES RLS
-- ============================================================

ALTER TABLE character_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all character votes" ON character_votes;
CREATE POLICY "Users can view all character votes" ON character_votes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own votes" ON character_votes;
CREATE POLICY "Users can insert their own votes" ON character_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own votes" ON character_votes;
CREATE POLICY "Users can update their own votes" ON character_votes
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own votes" ON character_votes;
CREATE POLICY "Users can delete their own votes" ON character_votes
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- 6. GRANTS
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON character_votes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON reactions TO authenticated;
