-- Migration 019: Fix deleteAccount FK issue + Create favorite_actor_votes table

-- Fix: Add ON DELETE SET NULL to shared_list_items.added_by
ALTER TABLE shared_list_items 
  DROP CONSTRAINT IF EXISTS shared_list_items_added_by_fkey,
  ADD CONSTRAINT shared_list_items_added_by_fkey 
    FOREIGN KEY (added_by) REFERENCES profiles(id) ON DELETE SET NULL;

-- Create favorite_actor_votes table
CREATE TABLE IF NOT EXISTS favorite_actor_votes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('tv', 'movie')),
  person_id INTEGER NOT NULL,
  character_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tmdb_id, media_type)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_fav_actor_votes_user ON favorite_actor_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_fav_actor_votes_tmdb ON favorite_actor_votes(tmdb_id, media_type);
CREATE INDEX IF NOT EXISTS idx_fav_actor_votes_person ON favorite_actor_votes(person_id);

-- RLS
ALTER TABLE favorite_actor_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view favorite actor votes" ON favorite_actor_votes
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own votes" ON favorite_actor_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own votes" ON favorite_actor_votes
  FOR DELETE USING (auth.uid() = user_id);

-- Grants
GRANT SELECT, INSERT, DELETE ON favorite_actor_votes TO authenticated;
