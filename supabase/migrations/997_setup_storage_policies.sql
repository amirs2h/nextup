-- ============================================================
-- MIGRATION: Storage RLS policies for avatars and headers buckets
-- Run this in Supabase SQL Editor
-- NOTE: Do NOT run ALTER TABLE on storage.objects (it's owned by Supabase)
-- ============================================================

-- ============================================================
-- AVATARS BUCKET POLICIES
-- ============================================================

-- Anyone can view avatars (public bucket)
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars" ON storage.objects 
  FOR SELECT USING (bucket_id = 'avatars');

-- Authenticated users can upload to their own folder
DROP POLICY IF EXISTS "Users can upload avatars" ON storage.objects;
CREATE POLICY "Users can upload avatars" ON storage.objects 
  FOR INSERT TO authenticated 
  WITH CHECK (
    bucket_id = 'avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own avatar
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar" ON storage.objects 
  FOR UPDATE TO authenticated 
  USING (
    bucket_id = 'avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own avatar
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar" ON storage.objects 
  FOR DELETE TO authenticated 
  USING (
    bucket_id = 'avatars' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- HEADERS BUCKET POLICIES
-- ============================================================

-- Anyone can view headers (public bucket)
DROP POLICY IF EXISTS "Anyone can view headers" ON storage.objects;
CREATE POLICY "Anyone can view headers" ON storage.objects 
  FOR SELECT USING (bucket_id = 'headers');

-- Authenticated users can upload to their own folder
DROP POLICY IF EXISTS "Users can upload headers" ON storage.objects;
CREATE POLICY "Users can upload headers" ON storage.objects 
  FOR INSERT TO authenticated 
  WITH CHECK (
    bucket_id = 'headers' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own header
DROP POLICY IF EXISTS "Users can update own header" ON storage.objects;
CREATE POLICY "Users can update own header" ON storage.objects 
  FOR UPDATE TO authenticated 
  USING (
    bucket_id = 'headers' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own header
DROP POLICY IF EXISTS "Users can delete own header" ON storage.objects;
CREATE POLICY "Users can delete own header" ON storage.objects 
  FOR DELETE TO authenticated 
  USING (
    bucket_id = 'headers' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- DONE
-- ============================================================
