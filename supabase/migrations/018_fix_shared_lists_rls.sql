-- Migration 018: Fix Shared Lists RLS policies
-- The previous RLS policies had ambiguous column references

-- Drop old policies
DROP POLICY IF EXISTS "Members can view shared lists" ON shared_lists;
DROP POLICY IF EXISTS "Members can view members" ON shared_list_members;

-- Create new policies with proper table aliases
CREATE POLICY "Members can view shared lists" ON shared_lists FOR SELECT 
  USING (
    auth.uid() = creator_id 
    OR EXISTS (
      SELECT 1 FROM shared_list_members slm 
      WHERE slm.list_id = shared_lists.id AND slm.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can view members" ON shared_list_members FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM shared_list_members slm 
      WHERE slm.list_id = shared_list_members.list_id AND slm.user_id = auth.uid()
    )
  );
