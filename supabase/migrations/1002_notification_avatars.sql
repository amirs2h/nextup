-- ============================================================
-- MIGRATION 1002: Add avatar URLs to comment notification data
-- ============================================================

-- 1. Update notify_followers_on_comment to include avatar_url
CREATE OR REPLACE FUNCTION notify_followers_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  commenter_username TEXT;
  commenter_avatar TEXT;
  follower_record RECORD;
  content_title TEXT;
BEGIN
  SELECT username, avatar_url INTO commenter_username, commenter_avatar
  FROM public.profiles WHERE id = NEW.user_id;

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
        'comment_id', NEW.id,
        'avatar_url', commenter_avatar
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Update notify_on_reply to include both replier and parent owner avatars
CREATE OR REPLACE FUNCTION notify_on_reply()
RETURNS TRIGGER AS $$
DECLARE
  parent_owner_id UUID;
  replier_username TEXT;
  replier_avatar TEXT;
  parent_owner_avatar TEXT;
  content_title TEXT;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT user_id INTO parent_owner_id FROM public.comments WHERE id = NEW.parent_id;

  IF parent_owner_id IS NULL OR parent_owner_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  SELECT username, avatar_url INTO replier_username, replier_avatar
  FROM public.profiles WHERE id = NEW.user_id;

  SELECT avatar_url INTO parent_owner_avatar
  FROM public.profiles WHERE id = parent_owner_id;

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
      'parent_id', NEW.parent_id,
      'avatar_url', replier_avatar,
      'parent_avatar_url', parent_owner_avatar
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Update notify_on_comment_like to include liker avatar
CREATE OR REPLACE FUNCTION notify_on_comment_like()
RETURNS TRIGGER AS $$
DECLARE
  comment_owner_id UUID;
  liker_username TEXT;
  liker_avatar TEXT;
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

  SELECT username, avatar_url INTO liker_username, liker_avatar
  FROM public.profiles WHERE id = NEW.user_id;

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
        'episode_number', comment_episode,
        'avatar_url', liker_avatar
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
