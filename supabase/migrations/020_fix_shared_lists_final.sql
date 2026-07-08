-- Fix shared_list_members RLS to allow users to see their own row
DROP POLICY IF EXISTS "Members can view members" ON shared_list_members;
CREATE POLICY "Members can view members" ON shared_list_members FOR SELECT 
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM shared_list_members slm 
      WHERE slm.list_id = shared_list_members.list_id AND slm.user_id = auth.uid()
    )
  );

-- Fix shared_list_members INSERT/DELETE to check role
DROP POLICY IF EXISTS "Admins can add members" ON shared_list_members;
CREATE POLICY "Admins can add members" ON shared_list_members FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM shared_list_members 
      WHERE list_id = shared_list_members.list_id 
        AND user_id = auth.uid() 
        AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can remove members" ON shared_list_members;
CREATE POLICY "Admins can remove members" ON shared_list_members FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM shared_list_members 
      WHERE list_id = shared_list_members.list_id 
        AND user_id = auth.uid() 
        AND role = 'admin'
    )
  );
