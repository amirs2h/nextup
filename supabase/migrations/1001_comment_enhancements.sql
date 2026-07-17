-- ============================================================
-- MIGRATION 1001: Comment System Enhancements
-- ============================================================
-- Adds: parent_id (threading), title (content name),
-- reply notifications, fix comment_like navigation bug
-- ============================================================

-- 1. Add columns to comments table
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE;
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS title TEXT;

-- 2. Index for threading queries
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON public.comments(parent_id);

-- 3. Update comments_with_likes view to include reply_count
DROP VIEW IF EXISTS public.comments_with_likes;
CREATE VIEW public.comments_with_likes
  WITH (security_invoker = true)
AS
  SELECT c.*,
    COUNT(cl.id) AS likes_count,
    (SELECT COUNT(*) FROM public.comments r WHERE r.parent_id = c.id) AS reply_count
  FROM public.comments c
  LEFT JOIN public.comment_likes cl ON cl.comment_id = c.id
  GROUP BY c.id;

-- 4. Update notify_followers_on_comment to include title
CREATE OR REPLACE FUNCTION notify_followers_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  commenter_username TEXT;
  follower_record RECORD;
  content_title TEXT;
BEGIN
  SELECT username INTO commenter_username FROM public.profiles WHERE id = NEW.user_id;
  content_title := COALESCE(NEW.title, 'a movie/show');

  FOR follower_record IN
    SELECT follower_id FROM public.follows WHERE following_id = NEW.user_id
  LOOP
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      follower_record.follower_id,
      'new_comment',
      COALESCE(commenter_username, 'Someone') || ' commented on ' || content_title,
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

-- 5. New trigger: notify comment owner when someone replies
CREATE OR REPLACE FUNCTION notify_on_reply()
RETURNS TRIGGER AS $$
DECLARE
  parent_owner_id UUID;
  replier_username TEXT;
  content_title TEXT;
BEGIN
  -- Only fire for replies (comments with parent_id)
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get the parent comment's owner
  SELECT user_id INTO parent_owner_id FROM public.comments WHERE id = NEW.parent_id;

  -- Don't notify if replying to your own comment
  IF parent_owner_id IS NULL OR parent_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  SELECT username INTO replier_username FROM public.profiles WHERE id = NEW.user_id;
  content_title := COALESCE(NEW.title, 'a movie/show');

  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    parent_owner_id,
    'comment_reply',
    COALESCE(replier_username, 'Someone') || ' replied to your comment on ' || content_title,
    LEFT(NEW.content, 100),
    jsonb_build_object(
      'tmdb_id', NEW.tmdb_id,
      'media_type', NEW.media_type,
      'season_number', NEW.season_number,
      'episode_number', NEW.episode_number,
      'replier_id', NEW.user_id,
      'comment_id', NEW.id,
      'parent_id', NEW.parent_id
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_reply_created ON public.comments;
CREATE TRIGGER on_reply_created
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION notify_on_reply();

-- 6. Fix comment_like notification: include tmdb_id/media_type in data
CREATE OR REPLACE FUNCTION notify_on_comment_like()
RETURNS TRIGGER AS $$
DECLARE
  comment_owner_id UUID;
  liker_username TEXT;
  comment_content TEXT;
  comment_tmdb_id INTEGER;
  comment_media_type TEXT;
  comment_season INTEGER;
  comment_episode INTEGER;
BEGIN
  SELECT user_id, content, tmdb_id, media_type, season_number, episode_number
  INTO comment_owner_id, comment_content, comment_tmdb_id, comment_media_type, comment_season, comment_episode
  FROM public.comments WHERE id = NEW.comment_id;

  IF comment_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  SELECT username INTO liker_username FROM public.profiles WHERE id = NEW.user_id;

  IF comment_owner_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      comment_owner_id,
      'comment_like',
      COALESCE(liker_username, 'Someone') || ' liked your comment',
      LEFT(comment_content, 100),
      jsonb_build_object(
        'liker_id', NEW.user_id,
        'comment_id', NEW.comment_id,
        'tmdb_id', comment_tmdb_id,
        'media_type', comment_media_type,
        'season_number', comment_season,
        'episode_number', comment_episode
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
