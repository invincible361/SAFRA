-- Fix for Profile Storage Bucket
-- Run this script to add the missing profiles storage bucket for user profile images

-- Create storage bucket for profile images
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true);

-- Create storage policies for profiles bucket
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

-- Grant permissions for storage
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Create function to clean up old profile images when user updates their profile
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

-- Create trigger for cleanup
CREATE TRIGGER cleanup_old_profile_image_trigger
    AFTER UPDATE OF profile_image_url ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION cleanup_old_profile_image();