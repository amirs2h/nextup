-- ============================================================
-- MIGRATION 1009: Denormalize title/poster_path into list item tables
-- Eliminates N+1 TMDB API calls when loading shared/custom list details
-- ============================================================

-- 1. Add title and poster_path to shared_list_items
ALTER TABLE public.shared_list_items ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.shared_list_items ADD COLUMN IF NOT EXISTS poster_path TEXT;

-- 2. Add title and poster_path to custom_list_items
ALTER TABLE public.custom_list_items ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.custom_list_items ADD COLUMN IF NOT EXISTS poster_path TEXT;

-- 3. Indexes for faster sorting
CREATE INDEX IF NOT EXISTS idx_shared_list_items_title ON public.shared_list_items(title);
CREATE INDEX IF NOT EXISTS idx_custom_list_items_title ON public.custom_list_items(title);

-- ============================================================
-- DONE
-- ============================================================
