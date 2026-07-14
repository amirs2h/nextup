-- ============================================================
-- MIGRATION: Comment & Like notification triggers
-- ============================================================

-- 1. Notify followers when someone they follow comments
CREATE OR REPLACE FUNCTION notify_followers_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  commenter_username TEXT;
  follower_record RECORD;
BEGIN
  -- Get commenter's username
  SELECT username INTO commenter_username FROM public.profiles WHERE id = NEW.user_id;
  
  -- Notify all followers of the commenter
  FOR follower_record IN 
    SELECT follower_id FROM public.follows WHERE following_id = NEW.user_id
  LOOP
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      follower_record.follower_id,
      'new_comment',
      COALESCE(commenter_username, 'Someone') || ' commented',
      LEFT(NEW.content, 100),
      jsonb_build_object(
        'tmdb_id', NEW.tmdb_id,
        'media_type', NEW.media_type,
        'season_number', NEW.season_number,
        'episode_number', NEW.episode_number,
        'commenter_id', NEW.user_id,
        'comment_id', NEW.id
      )
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Notify when someone likes your comment
CREATE OR REPLACE FUNCTION notify_on_comment_like()
RETURNS TRIGGER AS $$
DECLARE
  comment_owner_id UUID;
  liker_username TEXT;
  comment_content TEXT;
BEGIN
  -- Get comment owner and content
  SELECT user_id, content INTO comment_owner_id, comment_content 
  FROM public.comments WHERE id = NEW.comment_id;
  
  -- Don't notify if you like your own comment
  IF comment_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Get liker's username
  SELECT username INTO liker_username FROM public.profiles WHERE id = NEW.user_id;
  
  -- Notify the comment owner
  IF comment_owner_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      comment_owner_id,
      'comment_like',
      COALESCE(liker_username, 'Someone') || ' liked your comment',
      LEFT(comment_content, 100),
      jsonb_build_object(
        'liker_id', NEW.user_id,
        'comment_id', NEW.comment_id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create triggers
DROP TRIGGER IF EXISTS on_comment_created ON public.comments;
CREATE TRIGGER on_comment_created
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION notify_followers_on_comment();

DROP TRIGGER IF EXISTS on_comment_liked ON public.comment_likes;
CREATE TRIGGER on_comment_liked
  AFTER INSERT ON public.comment_likes
  FOR EACH ROW EXECUTE FUNCTION notify_on_comment_like();

-- ============================================================
-- DONE
-- ============================================================
