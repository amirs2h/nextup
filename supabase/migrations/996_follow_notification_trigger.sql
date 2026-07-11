-- ============================================================
-- MIGRATION: Follow notification trigger
-- When a user follows another user, create a notification
-- Run this when no other transactions are active
-- ============================================================

-- Step 1: Create function
CREATE OR REPLACE FUNCTION notify_on_follow()
RETURNS TRIGGER AS $$
DECLARE
  follower_username TEXT;
BEGIN
  SELECT username INTO follower_username FROM public.profiles WHERE id = NEW.follower_id;
  INSERT INTO public.notifications (user_id, type, title, data)
  VALUES (
    NEW.following_id,
    'follow',
    COALESCE(follower_username, 'Someone') || ' started following you',
    jsonb_build_object('follower_id', NEW.follower_id)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Step 2: Create trigger (separate statement to avoid deadlock)
CREATE TRIGGER on_follow_created
  AFTER INSERT ON public.follows
  FOR EACH ROW EXECUTE FUNCTION notify_on_follow();
