-- ============================================================
-- MIGRATION 1011: Persist user achievements + XP (never-revoke base)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_achievements (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  xp_awarded INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id
  ON public.user_achievements(user_id);

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_xp INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS level INT NOT NULL DEFAULT 1;

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ua_select" ON public.user_achievements;
CREATE POLICY "ua_select" ON public.user_achievements
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "ua_insert_own" ON public.user_achievements;
CREATE POLICY "ua_insert_own" ON public.user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "ua_delete_own" ON public.user_achievements;
CREATE POLICY "ua_delete_own" ON public.user_achievements
  FOR DELETE USING (auth.uid() = user_id);

GRANT SELECT, INSERT, DELETE ON public.user_achievements TO authenticated;

-- Recalc profile total_xp + level from user_achievements
CREATE OR REPLACE FUNCTION public.recalc_user_xp(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_xp INT;
  v_level INT;
BEGIN
  SELECT COALESCE(SUM(xp_awarded), 0) INTO v_xp
  FROM public.user_achievements
  WHERE user_id = p_user_id;

  v_level := (v_xp / 100) + 1;

  UPDATE public.profiles
  SET total_xp = v_xp,
      level = v_level
  WHERE id = p_user_id;
END;
$$;

-- Trigger after insert/delete on user_achievements
CREATE OR REPLACE FUNCTION public.trg_user_achievements_recalc()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.recalc_user_xp(OLD.user_id);
    RETURN OLD;
  ELSE
    PERFORM public.recalc_user_xp(NEW.user_id);
    RETURN NEW;
  END IF;
END;
$$;

DROP TRIGGER IF EXISTS user_achievements_recalc ON public.user_achievements;
CREATE TRIGGER user_achievements_recalc
  AFTER INSERT OR DELETE ON public.user_achievements
  FOR EACH ROW EXECUTE FUNCTION public.trg_user_achievements_recalc();

NOTIFY pgrst, 'reload schema';
