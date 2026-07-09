-- Fix: Recreate comments_with_likes view without SECURITY DEFINER
-- This ensures the view uses the querying user's permissions (SECURITY INVOKER)

DROP VIEW IF EXISTS public.comments_with_likes;

CREATE OR REPLACE VIEW public.comments_with_likes
  WITH (security_invoker = true)
AS
  SELECT c.*, COUNT(cl.id) AS likes_count
  FROM comments c
  LEFT JOIN comment_likes cl ON cl.comment_id = c.id
  GROUP BY c.id;
