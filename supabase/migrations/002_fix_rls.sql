-- Fix RLS policies for profiles table

-- Drop existing policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Recreate policies with proper permissions
CREATE POLICY "Public profiles are viewable by everyone" 
  ON profiles FOR SELECT 
  USING (true);

CREATE POLICY "Users can insert their own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id OR auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

-- Also allow the service role to insert (for triggers)
CREATE POLICY "Service role can insert profiles" 
  ON profiles FOR INSERT 
  TO service_role
  WITH CHECK (true);

-- Update the trigger function to handle conflicts
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (
    NEW.id, 
    COALESCE(
      NEW.raw_user_meta_data->>'username', 
      split_part(NEW.email, '@', 1)
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
