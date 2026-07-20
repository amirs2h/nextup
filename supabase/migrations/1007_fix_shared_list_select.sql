-- ============================================================
-- MIGRATION 1007: Fix shared_lists SELECT policy
-- ============================================================
-- The SELECT policy on shared_lists requires membership in
-- shared_list_members, but when creating a new list the creator
-- hasn't been added as a member yet. This causes a 500 error
-- on the .select('id') after INSERT.
-- Fix: also allow the creator to view their own lists.
-- ============================================================

DROP POLICY IF EXISTS "Members can view shared lists" ON shared_lists;

CREATE POLICY "Members can view shared lists" ON shared_lists 
  FOR SELECT USING (
    -- Creator can always view their own lists
    auth.uid() = creator_id
    OR
    -- Members can view lists they belong to
    EXISTS (
      SELECT 1 FROM shared_list_members 
      WHERE list_id = id 
        AND user_id = auth.uid()
    )
  );
