-- Migration 014: Shared lists fixes
-- 1. Add updated_at trigger to shared_lists
-- 2. Add indexes for performance

-- Add updated_at trigger
CREATE TRIGGER update_shared_lists_updated_at
  BEFORE UPDATE ON shared_lists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add indexes for shared_list_members
CREATE INDEX IF NOT EXISTS idx_shared_list_members_list_id ON shared_list_members(list_id);
CREATE INDEX IF NOT EXISTS idx_shared_list_members_user_id ON shared_list_members(user_id);

-- Add indexes for shared_list_items
CREATE INDEX IF NOT EXISTS idx_shared_list_items_list_id ON shared_list_items(list_id);
CREATE INDEX IF NOT EXISTS idx_shared_list_items_added_by ON shared_list_items(added_by);
