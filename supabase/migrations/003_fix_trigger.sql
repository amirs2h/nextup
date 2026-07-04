-- Fix trigger to handle username conflicts

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create improved trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter INTEGER := 0;
BEGIN
  -- Get base username from metadata or email
  base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    split_part(NEW.email, '@', 1)
  );
  
  -- Try the base username first
  final_username := base_username;
  
  -- Loop until we find a unique username
  LOOP
    BEGIN
      INSERT INTO public.profiles (id, username)
      VALUES (NEW.id, final_username);
      EXIT; -- Success, exit loop
    EXCEPTION WHEN unique_violation THEN
      -- Username conflict, try with counter
      counter := counter + 1;
      final_username := base_username || '_' || counter::TEXT;
      
      -- Safety check to avoid infinite loop
      IF counter > 100 THEN
        -- Use timestamp as fallback
        final_username := base_username || '_' || extract(epoch from now())::TEXT;
        INSERT INTO public.profiles (id, username) VALUES (NEW.id, final_username);
        EXIT;
      END IF;
    END;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Also fix any existing profiles with duplicate usernames (if any)
DO $$
DECLARE
  dup RECORD;
BEGIN
  FOR dup IN 
    SELECT id, username, 
           ROW_NUMBER() OVER (PARTITION BY username ORDER BY created_at) as rn
    FROM profiles
    WHERE username IN (
      SELECT username FROM profiles GROUP BY username HAVING COUNT(*) > 1
    )
  LOOP
    IF dup.rn > 1 THEN
      UPDATE profiles 
      SET username = dup.username || '_' || dup.rn::TEXT
      WHERE id = dup.id;
    END IF;
  END LOOP;
END $$;
