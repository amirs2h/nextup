-- Fix Watchlist/Favorites UPDATE RLS + Notifications INSERT
-- Run this in Supabase SQL Editor

-- Watchlist needs UPDATE policy for upsert
CREATE POLICY "Users can update own watchlist" ON watchlist FOR UPDATE USING (auth.uid() = user_id);

-- Favorites needs UPDATE policy for upsert
CREATE POLICY "Users can update own favorites" ON favorites FOR UPDATE USING (auth.uid() = user_id);

-- Notifications needs INSERT policy
CREATE POLICY "Users can insert notifications" ON notifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Also add DELETE policy for notifications (users should be able to dismiss)
CREATE POLICY "Users can delete own notifications" ON notifications FOR DELETE USING (auth.uid() = user_id);
