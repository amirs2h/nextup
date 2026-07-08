-- Fix: Grant UPDATE privilege on favorite_actor_votes
-- Without this, the UPDATE RLS policy from migration 021 won't work
GRANT UPDATE ON favorite_actor_votes TO authenticated;
