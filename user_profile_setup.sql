-- SAFRA User Profile Table Setup
-- Run this script in your Supabase SQL editor to add user profile functionality

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

-- Enable Row Level Security
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

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for user_profiles table
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
GRANT EXECUTE ON FUNCTION get_or_create_user_profile() TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles(updated_at);