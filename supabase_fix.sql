-- Fix for SAFRA Community Chat
-- Run this in your Supabase SQL Editor

-- Drop the table if it exists (to start fresh)
DROP TABLE IF EXISTS community_messages;

-- Create the community_messages table
CREATE TABLE community_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_email TEXT NOT NULL,
    user_name TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view messages" ON community_messages
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert messages" ON community_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Insert a welcome message (only if there are existing users)
-- We'll insert this after a real user creates their first message
-- This avoids foreign key constraint issues

-- Grant permissions
GRANT ALL ON community_messages TO authenticated;
GRANT ALL ON community_messages TO anon;
