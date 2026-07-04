-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  language TEXT DEFAULT 'en' CHECK (language IN ('en', 'fa')),
  theme TEXT DEFAULT 'dark' CHECK (theme IN ('dark', 'light', 'system')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Watchlist table
CREATE TABLE IF NOT EXISTS watchlist (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('tv', 'movie')),
  list_name TEXT DEFAULT 'default',
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tmdb_id, media_type, list_name)
);

-- Watch History table
CREATE TABLE IF NOT EXISTS watch_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('tv', 'movie')),
  season_number INTEGER,
  episode_number INTEGER,
  watched_at TIMESTAMPTZ DEFAULT NOW()
);

-- Favorites table
CREATE TABLE IF NOT EXISTS favorites (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('tv', 'movie')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tmdb_id, media_type)
);

-- Comments table
CREATE TABLE IF NOT EXISTS comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('tv', 'movie')),
  season_number INTEGER,
  episode_number INTEGER,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comment Likes table
CREATE TABLE IF NOT EXISTS comment_likes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, comment_id)
);

-- Follows table
CREATE TABLE IF NOT EXISTS follows (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Reactions table
CREATE TABLE IF NOT EXISTS reactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  season_number INTEGER NOT NULL,
  episode_number INTEGER NOT NULL,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tmdb_id, season_number, episode_number)
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Custom Lists table
CREATE TABLE IF NOT EXISTS custom_lists (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Custom List Items table
CREATE TABLE IF NOT EXISTS custom_list_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  list_id UUID REFERENCES custom_lists(id) ON DELETE CASCADE NOT NULL,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('tv', 'movie')),
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(list_id, tmdb_id, media_type)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_watchlist_user_id ON watchlist(user_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_media_type ON watchlist(media_type);
CREATE INDEX IF NOT EXISTS idx_watch_history_user_id ON watch_history(user_id);
CREATE INDEX IF NOT EXISTS idx_watch_history_tmdb_id ON watch_history(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_tmdb_id ON comments(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_comments_media_type ON comments(media_type);
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_reactions_tmdb_id ON reactions(tmdb_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE watch_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_list_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Profiles: Public read, owner write
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Watchlist: Owner only
CREATE POLICY "Users can view their own watchlist" ON watchlist FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert to their watchlist" ON watchlist FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete from their watchlist" ON watchlist FOR DELETE USING (auth.uid() = user_id);

-- Watch History: Owner only
CREATE POLICY "Users can view their own watch history" ON watch_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert to their watch history" ON watch_history FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete from their watch history" ON watch_history FOR DELETE USING (auth.uid() = user_id);

-- Favorites: Owner only
CREATE POLICY "Users can view their own favorites" ON favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert to their favorites" ON favorites FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete from their favorites" ON favorites FOR DELETE USING (auth.uid() = user_id);

-- Comments: Public read, owner write
CREATE POLICY "Comments are viewable by everyone" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can insert comments" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own comments" ON comments FOR DELETE USING (auth.uid() = user_id);

-- Comment Likes: Public read, owner write
CREATE POLICY "Comment likes are viewable by everyone" ON comment_likes FOR SELECT USING (true);
CREATE POLICY "Users can like comments" ON comment_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike comments" ON comment_likes FOR DELETE USING (auth.uid() = user_id);

-- Follows: Public read, owner write
CREATE POLICY "Follows are viewable by everyone" ON follows FOR SELECT USING (true);
CREATE POLICY "Users can follow others" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow others" ON follows FOR DELETE USING (auth.uid() = follower_id);

-- Reactions: Public read, owner write
CREATE POLICY "Reactions are viewable by everyone" ON reactions FOR SELECT USING (true);
CREATE POLICY "Users can add reactions" ON reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their reactions" ON reactions FOR UPDATE USING (auth.uid() = user_id);

-- Notifications: Owner only
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Custom Lists: Public read for public lists, owner read/write
CREATE POLICY "Public lists are viewable by everyone" ON custom_lists FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users can create lists" ON custom_lists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own lists" ON custom_lists FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own lists" ON custom_lists FOR DELETE USING (auth.uid() = user_id);

-- Custom List Items: Follow parent list policy
CREATE POLICY "List items viewable if list is viewable" ON custom_list_items FOR SELECT 
  USING (EXISTS (SELECT 1 FROM custom_lists WHERE id = list_id AND (is_public = true OR user_id = auth.uid())));
CREATE POLICY "Users can add items to their lists" ON custom_list_items FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM custom_lists WHERE id = list_id AND user_id = auth.uid()));
CREATE POLICY "Users can remove items from their lists" ON custom_list_items FOR DELETE 
  USING (EXISTS (SELECT 1 FROM custom_lists WHERE id = list_id AND user_id = auth.uid()));

-- Function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_custom_lists_updated_at
  BEFORE UPDATE ON custom_lists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
