-- Shared Lists: Create tables for collaborative lists
-- Run this in Supabase SQL Editor

-- Shared Lists table
CREATE TABLE IF NOT EXISTS shared_lists (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shared List Members table
CREATE TABLE IF NOT EXISTS shared_list_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  list_id UUID REFERENCES shared_lists(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(list_id, user_id)
);

-- Shared List Items table
CREATE TABLE IF NOT EXISTS shared_list_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  list_id UUID REFERENCES shared_lists(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('tv', 'movie')),
  added_by UUID REFERENCES profiles(id),
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(list_id, tmdb_id, media_type)
);

-- Enable RLS
ALTER TABLE shared_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_list_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_list_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shared_lists
CREATE POLICY "Members can view shared lists" ON shared_lists FOR SELECT 
  USING (EXISTS (SELECT 1 FROM shared_list_members WHERE list_id = id AND user_id = auth.uid()));

CREATE POLICY "Users can create shared lists" ON shared_lists FOR INSERT 
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update shared lists" ON shared_lists FOR UPDATE 
  USING (auth.uid() = creator_id);

CREATE POLICY "Creators can delete shared lists" ON shared_lists FOR DELETE 
  USING (auth.uid() = creator_id);

-- RLS Policies for shared_list_members
CREATE POLICY "Members can view members" ON shared_list_members FOR SELECT 
  USING (EXISTS (SELECT 1 FROM shared_list_members slm WHERE slm.list_id = shared_list_members.list_id AND slm.user_id = auth.uid()));

CREATE POLICY "Admins can add members" ON shared_list_members FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM shared_lists WHERE id = list_id AND creator_id = auth.uid()));

CREATE POLICY "Admins can remove members" ON shared_list_members FOR DELETE 
  USING (EXISTS (SELECT 1 FROM shared_lists WHERE id = list_id AND creator_id = auth.uid()));

-- RLS Policies for shared_list_items
CREATE POLICY "Members can view items" ON shared_list_items FOR SELECT 
  USING (EXISTS (SELECT 1 FROM shared_list_members WHERE list_id = shared_list_items.list_id AND user_id = auth.uid()));

CREATE POLICY "Members can add items" ON shared_list_items FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM shared_list_members WHERE list_id = shared_list_items.list_id AND user_id = auth.uid()));

CREATE POLICY "Members can remove items" ON shared_list_items FOR DELETE 
  USING (EXISTS (SELECT 1 FROM shared_list_members WHERE list_id = shared_list_items.list_id AND user_id = auth.uid()));

-- Grants
GRANT ALL ON shared_lists TO authenticated;
GRANT ALL ON shared_list_members TO authenticated;
GRANT ALL ON shared_list_items TO authenticated;
