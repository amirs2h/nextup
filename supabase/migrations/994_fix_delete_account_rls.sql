-- ============================================================
-- MIGRATION: Allow users to remove themselves from shared lists
-- This is needed for account deletion to work properly
-- ============================================================

-- Add policy for users to remove themselves from shared lists
DROP POLICY IF EXISTS "Users can remove themselves from shared lists" ON public.shared_list_members;
CREATE POLICY "Users can remove themselves from shared lists" ON public.shared_list_members 
  FOR DELETE 
  USING (auth.uid() = user_id);
