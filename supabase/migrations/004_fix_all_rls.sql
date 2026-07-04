-- Fix RLS for watch_history - ensure all operations work

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own watch history" ON watch_history;
DROP POLICY IF EXISTS "Users can insert to their watch history" ON watch_history;
DROP POLICY IF EXISTS "Users can delete from their watch history" ON watch_history;

-- Recreate with proper permissions
CREATE POLICY "Users can view their own watch history" 
  ON watch_history FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert to their watch history" 
  ON watch_history FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete from their watch history" 
  ON watch_history FOR DELETE 
  USING (auth.uid() = user_id);

-- Also ensure watchlist policies are correct
DROP POLICY IF EXISTS "Users can view their own watchlist" ON watchlist;
DROP POLICY IF EXISTS "Users can insert to their watchlist" ON watchlist;
DROP POLICY IF EXISTS "Users can delete from their watchlist" ON watchlist;

CREATE POLICY "Users can view their own watchlist" 
  ON watchlist FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert to their watchlist" 
  ON watchlist FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete from their watchlist" 
  ON watchlist FOR DELETE 
  USING (auth.uid() = user_id);

-- Ensure favorites policies are correct
DROP POLICY IF EXISTS "Users can view their own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can insert to their favorites" ON favorites;
DROP POLICY IF EXISTS "Users can delete from their favorites" ON favorites;

CREATE POLICY "Users can view their own favorites" 
  ON favorites FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert to their favorites" 
  ON favorites FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete from their favorites" 
  ON favorites FOR DELETE 
  USING (auth.uid() = user_id);

-- Ensure comments policies are correct
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON comments;
DROP POLICY IF EXISTS "Users can insert comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;

CREATE POLICY "Comments are viewable by everyone" 
  ON comments FOR SELECT 
  USING (true);

CREATE POLICY "Users can insert comments" 
  ON comments FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" 
  ON comments FOR DELETE 
  USING (auth.uid() = user_id);

-- Ensure comment_likes policies are correct
DROP POLICY IF EXISTS "Comment likes are viewable by everyone" ON comment_likes;
DROP POLICY IF EXISTS "Users can like comments" ON comment_likes;
DROP POLICY IF EXISTS "Users can unlike comments" ON comment_likes;

CREATE POLICY "Comment likes are viewable by everyone" 
  ON comment_likes FOR SELECT 
  USING (true);

CREATE POLICY "Users can like comments" 
  ON comment_likes FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike comments" 
  ON comment_likes FOR DELETE 
  USING (auth.uid() = user_id);

-- Ensure follows policies are correct
DROP POLICY IF EXISTS "Follows are viewable by everyone" ON follows;
DROP POLICY IF EXISTS "Users can follow others" ON follows;
DROP POLICY IF EXISTS "Users can unfollow others" ON follows;

CREATE POLICY "Follows are viewable by everyone" 
  ON follows FOR SELECT 
  USING (true);

CREATE POLICY "Users can follow others" 
  ON follows FOR INSERT 
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others" 
  ON follows FOR DELETE 
  USING (auth.uid() = follower_id);

-- Grant necessary permissions
GRANT ALL ON watch_history TO authenticated;
GRANT ALL ON watchlist TO authenticated;
GRANT ALL ON favorites TO authenticated;
GRANT ALL ON comments TO authenticated;
GRANT ALL ON comment_likes TO authenticated;
GRANT ALL ON follows TO authenticated;
