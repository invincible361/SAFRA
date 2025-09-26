-- SAFRA Profile Feature Complete Setup
-- This script sets up both the user_profiles table AND the profiles storage bucket
-- Run this in your Supabase SQL editor to fix profile functionality

-- Step 1: Create user_profiles table (if not exists)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    full_name TEXT,
    phone_number TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    bio TEXT,
    profile_image_url TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Create RLS policies for user_profiles
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own profile" ON user_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Step 4: Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Step 5: Create trigger for user_profiles table
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Create storage bucket for profile images
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Step 7: Create storage policies for profiles bucket
CREATE POLICY "Allow authenticated uploads to profiles" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'profiles');

CREATE POLICY "Allow public read access to profiles" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

CREATE POLICY "Allow users to update own profile images" ON storage.objects
    FOR UPDATE TO authenticated
    WITH CHECK (bucket_id = 'profiles');

CREATE POLICY "Allow users to delete own profile images" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'profiles' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Step 8: Create function to get or create user profile
CREATE OR REPLACE FUNCTION get_or_create_user_profile()
RETURNS user_profiles AS $$
DECLARE
    profile_record user_profiles;
BEGIN
    -- Try to get existing profile
    SELECT * INTO profile_record 
    FROM user_profiles 
    WHERE user_id = auth.uid();
    
    -- If profile doesn't exist, create it
    IF NOT FOUND THEN
        INSERT INTO user_profiles (user_id, full_name)
        VALUES (auth.uid(), COALESCE(auth.users()->>'full_name', 'User'))
        RETURNING * INTO profile_record;
    END IF;
    
    RETURN profile_record;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Step 9: Create function to clean up old profile images when user updates their profile
CREATE OR REPLACE FUNCTION cleanup_old_profile_image()
RETURNS TRIGGER AS $$
BEGIN
    -- If profile_image_url is being updated and old value exists
    IF NEW.profile_image_url IS DISTINCT FROM OLD.profile_image_url AND OLD.profile_image_url IS NOT NULL THEN
        -- Extract the file path from the old URL
        DECLARE
            old_path TEXT;
        BEGIN
            old_path := substring(OLD.profile_image_url from '/storage/v1/object/public/profiles/(.+)$');
            IF old_path IS NOT NULL THEN
                -- Delete the old file from storage
                DELETE FROM storage.objects 
                WHERE bucket_id = 'profiles' AND name = old_path;
            END IF;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Step 10: Create trigger for cleanup
CREATE TRIGGER cleanup_old_profile_image_trigger
    AFTER UPDATE OF profile_image_url ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION cleanup_old_profile_image();

-- Step 11: Grant permissions
GRANT ALL ON user_profiles TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_user_profile() TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Step 12: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles(updated_at);

-- Step 13: Test the setup (optional)
-- You can test by running: SELECT * FROM get_or_create_user_profile();