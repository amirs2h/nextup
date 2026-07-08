-- Fix Ratings Table RLS
-- Run this in Supabase SQL Editor

-- Enable RLS
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view all ratings" ON ratings FOR SELECT USING (true);
CREATE POLICY "Users can insert own ratings" ON ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own ratings" ON ratings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own ratings" ON ratings FOR DELETE USING (auth.uid() = user_id);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON ratings TO authenticated;
GRANT SELECT ON ratings TO anon;
