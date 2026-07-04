-- Simple ratings table creation
-- Run this ONE line at a time if needed

CREATE TABLE IF NOT EXISTS ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL,
  rating NUMERIC NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tmdb_id, media_type)
);
