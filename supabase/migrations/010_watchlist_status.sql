-- Watchlist Status: Add status field for categorization
-- Run this in Supabase SQL Editor

-- Add status column to watchlist
ALTER TABLE watchlist ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'watchlist';

-- Add check constraint for valid statuses
ALTER TABLE watchlist ADD CONSTRAINT watchlist_status_check 
  CHECK (status IN ('watchlist', 'watching', 'completed', 'up_to_date', 'stopped'));

-- Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_watchlist_status ON watchlist(user_id, status);

-- Update existing items to have 'watchlist' status
UPDATE watchlist SET status = 'watchlist' WHERE status IS NULL;
