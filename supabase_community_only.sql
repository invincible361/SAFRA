-- SAFRA Community Chat Database Setup (Simplified - No DigiLocker)
-- Run this script in your Supabase SQL editor

-- Create community_messages table
CREATE TABLE IF NOT EXISTS community_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_email TEXT NOT NULL,
    user_name TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_community_messages_created_at ON community_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_community_messages_user_id ON community_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_community_messages_user_email ON community_messages(user_email);

-- Enable Row Level Security (RLS)
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

-- Create a function to get community statistics
CREATE OR REPLACE FUNCTION get_community_stats()
RETURNS TABLE (
    total_messages BIGINT,
    total_users BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM community_messages) as total_messages,
        (SELECT COUNT(DISTINCT user_id) FROM community_messages) as total_users;
END;
$$ language 'plpgsql';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_community_stats() TO authenticated;

-- Insert a welcome message
INSERT INTO community_messages (user_id, user_email, user_name, message) 
VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid, -- System user ID
    'system@safra.app',
    'SAFRA Team',
    'Welcome to SAFRA Community! 🎉 Start chatting with other users to share safety tips and experiences.'
) ON CONFLICT DO NOTHING;
