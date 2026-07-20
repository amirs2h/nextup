-- ============================================================
-- MIGRATION 1010: Get common shared lists between two users
-- SECURITY DEFINER bypasses RLS to find shared lists where
-- both the current user and target user are members
-- ============================================================

CREATE OR REPLACE FUNCTION get_common_shared_lists(p_target_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  creator_id UUID,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT sl.id, sl.name, sl.description, sl.creator_id, sl.created_at
  FROM shared_lists sl
  WHERE sl.id IN (
    SELECT list_id FROM shared_list_members WHERE user_id = auth.uid()
  )
  AND sl.id IN (
    SELECT list_id FROM shared_list_members WHERE user_id = p_target_user_id
  )
  ORDER BY sl.created_at DESC;
$$;

NOTIFY pgrst, 'reload schema';
