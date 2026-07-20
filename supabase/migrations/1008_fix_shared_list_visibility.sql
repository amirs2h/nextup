-- ============================================================
-- MIGRATION 1008: Fix shared_list_members visibility
-- ============================================================
-- Problem: slm_select only shows user_id = auth.uid()
-- Creator can't see other members of their own lists.
-- Can't reference shared_lists directly (causes infinite recursion).
-- Solution: SECURITY DEFINER function that bypasses RLS.
-- ============================================================

-- 1. Create SECURITY DEFINER function to check list creator
CREATE OR REPLACE FUNCTION is_list_creator(p_list_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM shared_lists WHERE id = p_list_id AND creator_id = auth.uid()
  );
$$;

-- 2. Drop old restrictive policy
DROP POLICY IF EXISTS "slm_select" ON shared_list_members;

-- 3. New policy: users see own rows + creator sees all members
CREATE POLICY "slm_select" ON shared_list_members 
  FOR SELECT USING (
    user_id = auth.uid() 
    OR is_list_creator(list_id)
  );

-- 4. Also fix shared_lists SELECT to not cause recursion
-- The current policy references shared_list_members which is fine
-- because shared_list_members SELECT now doesn't reference shared_lists
-- (it uses the SECURITY DEFINER function instead)

-- 5. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
