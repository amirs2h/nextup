-- ============================================================
-- MIGRATION: Denormalize TMDB metadata into Supabase tables
-- This eliminates N+1 API patterns (80+ calls → 10)
-- ============================================================

-- 1. Add title and poster_path to watchlist
ALTER TABLE public.watchlist ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.watchlist ADD COLUMN IF NOT EXISTS poster_path TEXT;

-- 2. Add title and poster_path to favorites
ALTER TABLE public.favorites ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.favorites ADD COLUMN IF NOT EXISTS poster_path TEXT;

-- 3. Add title and poster_path to watch_history
ALTER TABLE public.watch_history ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.watch_history ADD COLUMN IF NOT EXISTS poster_path TEXT;

-- 4. Add index for faster sorting by title
CREATE INDEX IF NOT EXISTS idx_watchlist_title ON public.watchlist(title);
CREATE INDEX IF NOT EXISTS idx_favorites_title ON public.favorites(title);

-- ============================================================
-- DONE
-- ============================================================
