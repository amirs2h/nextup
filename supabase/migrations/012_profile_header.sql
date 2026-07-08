-- Profile Header Image: Add header_image_url to profiles
-- Run this in Supabase SQL Editor

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS header_image_url TEXT;
