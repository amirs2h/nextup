-- ============================================================
-- MIGRATION 1014: Add runtime_minutes to watch_history
-- Enables accurate watch time from TMDB runtime/episode_run_time
-- ============================================================

ALTER TABLE public.watch_history
  ADD COLUMN IF NOT EXISTS runtime_minutes INT;

CREATE INDEX IF NOT EXISTS idx_watch_history_runtime
  ON public.watch_history(runtime_minutes);

-- ============================================================
-- MIGRATION 1014b: Fix get_user_stats — consistent counting
-- episode_number > 0 for TV; SUM(runtime_minutes) for hours
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS TABLE(
  total_shows BIGINT,
  total_movies BIGINT,
  total_episodes BIGINT,
  total_hours NUMERIC
) AS $$
  SELECT
    COUNT(DISTINCT CASE
      WHEN wh.media_type = 'tv'
        AND wh.episode_number IS NOT NULL
        AND wh.episode_number > 0
      THEN wh.tmdb_id
    END)::BIGINT as total_shows,
    COUNT(DISTINCT CASE WHEN wh.media_type = 'movie' THEN wh.tmdb_id END)::BIGINT as total_movies,
    COUNT(CASE
      WHEN wh.media_type = 'tv'
        AND wh.episode_number IS NOT NULL
        AND wh.episode_number > 0
      THEN 1
    END)::BIGINT as total_episodes,
    COALESCE(SUM(
      CASE
        WHEN wh.runtime_minutes IS NOT NULL AND wh.runtime_minutes > 0
          THEN wh.runtime_minutes
        WHEN wh.media_type = 'tv' THEN 45
        ELSE 120
      END
    ), 0) / 60.0 as total_hours
  FROM watch_history wh
  WHERE wh.user_id = target_user_id;
$$ LANGUAGE sql STABLE;

NOTIFY pgrst, 'reload schema';
