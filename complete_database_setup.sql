-- SAFRA Complete Database Setup
-- Run this script in your Supabase SQL editor to set up all required tables and storage

-- Create user_profiles table to store editable user information
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

-- Enable Row Level Security for user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own profile" ON user_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Create evidence table for storing evidence uploads
CREATE TABLE IF NOT EXISTS evidence (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('Harassment', 'Assault', 'Stalking', 'Theft', 'Accident', 'Other')),
    severity NUMERIC(2,1) NOT NULL CHECK (severity >= 1.0 AND severity <= 5.0),
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT NOT NULL,
    notes TEXT,
    tags TEXT[],
    photo_urls TEXT[],
    video_urls TEXT[],
    is_anonymous BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for evidence
ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for evidence
CREATE POLICY "Users can view their own evidence" ON evidence
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own evidence" ON evidence
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own evidence" ON evidence
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own evidence" ON evidence
    FOR DELETE USING (auth.uid() = user_id);

-- Create community_messages table
CREATE TABLE IF NOT EXISTS community_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_email TEXT NOT NULL,
    user_name TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for community_messages
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for community_messages
CREATE POLICY "Users can view all community messages" ON community_messages
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert messages" ON community_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own messages" ON community_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" ON community_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_evidence_updated_at_trigger
    BEFORE UPDATE ON evidence
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create storage bucket for evidence files
INSERT INTO storage.buckets (id, name, public) VALUES ('evidence', 'evidence', true);

-- Create storage policies for evidence bucket
CREATE POLICY "Allow authenticated uploads" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'evidence');

CREATE POLICY "Allow public read access" ON storage.objects
    FOR SELECT USING (bucket_id = 'evidence');

CREATE POLICY "Allow users to delete own files" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'evidence' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Create function to get or create user profile
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
        VALUES (auth.uid(), auth.users()->full_name)
        RETURNING * INTO profile_record;
    END IF;
    
    RETURN profile_record;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Grant permissions
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON evidence TO authenticated;
GRANT ALL ON community_messages TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_user_profile() TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles(updated_at);
CREATE INDEX IF NOT EXISTS idx_evidence_user_id ON evidence(user_id);
CREATE INDEX IF NOT EXISTS idx_evidence_created_at ON evidence(created_at);
CREATE INDEX IF NOT EXISTS idx_community_messages_created_at ON community_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_community_messages_user_id ON community_messages(user_id);

-- Insert sample data for testing (optional)
-- INSERT INTO community_messages (user_id, user_email, user_name, message) VALUES
-- (auth.uid(), 'test@example.com', 'Test User', 'Welcome to SAFRA Community!');

-- Grant access to public schema
GRANT USAGE ON SCHEMA public TO authenticated;