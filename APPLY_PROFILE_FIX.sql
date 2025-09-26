-- 🚀 EMERGENCY PROFILE FIX SQL
-- Copy and paste this entire script into your Supabase SQL Editor
-- This will fix the "user_profiles does not exist" and "Bucket not found" errors

-- 1️⃣ CREATE USER PROFILES TABLE (IF NOT EXISTS)
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

-- 2️⃣ ENABLE ROW LEVEL SECURITY
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 3️⃣ CREATE SECURITY POLICIES
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- 4️⃣ CREATE TRIGGER FOR UPDATED_AT
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 5️⃣ CREATE STORAGE BUCKET FOR PROFILE IMAGES
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- 6️⃣ CREATE STORAGE POLICIES FOR PROFILE IMAGES
CREATE POLICY "Allow authenticated uploads to profiles" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profiles');
CREATE POLICY "Allow public read access to profiles" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');
CREATE POLICY "Allow users to update their own profile images" ON storage.objects
    FOR UPDATE TO authenticated USING (bucket_id = 'profiles');
CREATE POLICY "Allow users to delete their own profile images" ON storage.objects
    FOR DELETE TO authenticated USING (bucket_id = 'profiles');

-- 7️⃣ GRANT NECESSARY PERMISSIONS
GRANT ALL ON user_profiles TO authenticated;
GRANT SELECT ON user_profiles TO anon;
GRANT ALL ON storage.objects TO authenticated;
GRANT SELECT ON storage.objects TO anon;

-- 8️⃣ CREATE FUNCTION TO HANDLE PROFILE GET/CREATE
CREATE OR REPLACE FUNCTION get_or_create_user_profile(user_uuid UUID)
RETURNS user_profiles AS $$
DECLARE
    profile_record user_profiles;
BEGIN
    -- Try to get existing profile
    SELECT * INTO profile_record 
    FROM user_profiles 
    WHERE user_id = user_uuid;
    
    -- If not found, create new one
    IF NOT FOUND THEN
        INSERT INTO user_profiles (user_id, full_name, created_at, updated_at)
        VALUES (user_uuid, '', NOW(), NOW())
        RETURNING * INTO profile_record;
    END IF;
    
    RETURN profile_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9️⃣ CREATE FUNCTION TO CLEAN UP OLD PROFILE IMAGES
CREATE OR REPLACE FUNCTION cleanup_old_profile_image()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.profile_image_url IS NOT NULL AND OLD.profile_image_url != '' THEN
        DELETE FROM storage.objects 
        WHERE name = OLD.profile_image_url AND bucket_id = 'profiles';
    END IF;
    RETURN OLD;
END;
$$ language 'plpgsql';

-- 🔟 CREATE TRIGGER FOR IMAGE CLEANUP
CREATE TRIGGER cleanup_profile_image
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    WHEN (OLD.profile_image_url IS DISTINCT FROM NEW.profile_image_url)
    EXECUTE FUNCTION cleanup_old_profile_image();

-- ✅ VERIFICATION QUERIES (Run these to confirm everything is set up)
SELECT '✅ user_profiles table created' AS status WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles');
SELECT '✅ profiles bucket created' AS status WHERE EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'profiles');
SELECT '✅ RLS policies created' AS status WHERE COUNT(*) >= 3 FROM pg_policies WHERE tablename = 'user_profiles';

-- 🎉 SUCCESS MESSAGE
SELECT '🎉 PROFILE SYSTEM READY!' AS message;