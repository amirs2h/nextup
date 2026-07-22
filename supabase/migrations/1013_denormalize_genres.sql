-- ============================================================
-- MIGRATION 1013: Denormalize genres + origin countries
-- Enables reliable genre/country achievements without N+1 TMDB
-- ============================================================

ALTER TABLE public.watch_history
  ADD COLUMN IF NOT EXISTS genres TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS origin_countries TEXT[] DEFAULT '{}';

ALTER TABLE public.watchlist
  ADD COLUMN IF NOT EXISTS genres TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS origin_countries TEXT[] DEFAULT '{}';

ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS genres TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS origin_countries TEXT[] DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_watch_history_genres
  ON public.watch_history USING GIN (genres);

CREATE INDEX IF NOT EXISTS idx_watchlist_genres
  ON public.watchlist USING GIN (genres);

CREATE INDEX IF NOT EXISTS idx_favorites_genres
  ON public.favorites USING GIN (genres);

NOTIFY pgrst, 'reload schema';
