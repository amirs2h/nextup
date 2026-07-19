-- ============================================================
-- MIGRATION 1006: Fix shared_list_members INSERT policy
-- ============================================================
-- The current policy (from migration 020) requires the user
-- to already be an admin in shared_list_members, but when
-- creating a new list the creator hasn't been added yet.
-- Fix: also allow the creator of the list to add members.
-- ============================================================

DROP POLICY IF EXISTS "Admins can add members" ON shared_list_members;

CREATE POLICY "Admins can add members" ON shared_list_members 
  FOR INSERT WITH CHECK (
    -- Creator of the list can always add members
    EXISTS (
      SELECT 1 FROM shared_lists 
      WHERE id = list_id 
        AND creator_id = auth.uid()
    )
    OR
    -- Existing admins can also add members
    EXISTS (
      SELECT 1 FROM shared_list_members 
      WHERE list_id = shared_list_members.list_id 
        AND user_id = auth.uid() 
        AND role = 'admin'
    )
  );
