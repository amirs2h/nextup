-- ============================================================
-- MIGRATION 1020: Add vote_average to watchlist
-- ============================================================

ALTER TABLE public.watchlist ADD COLUMN IF NOT EXISTS vote_average NUMERIC(3,1) DEFAULT 0;

NOTIFY pgrst, 'reload schema';
