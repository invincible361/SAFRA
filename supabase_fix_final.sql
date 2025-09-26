-- SAFRA Community Chat - Final Fix
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

-- Grant permissions
GRANT ALL ON community_messages TO authenticated;
GRANT ALL ON community_messages TO anon;

-- Create a function to add welcome message when first user joins
CREATE OR REPLACE FUNCTION add_welcome_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if this is the first message
    IF (SELECT COUNT(*) FROM community_messages) = 1 THEN
        -- Insert a system welcome message
        INSERT INTO community_messages (user_id, user_email, user_name, message)
        VALUES (
            NEW.user_id, -- Use the same user_id as the first message
            'system@safra.app',
            'SAFRA Team',
            'Welcome to SAFRA Community! 🎉 Start chatting with other users.'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to add welcome message
CREATE TRIGGER welcome_message_trigger
    AFTER INSERT ON community_messages
    FOR EACH ROW
    EXECUTE FUNCTION add_welcome_message();

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION add_welcome_message() TO authenticated;
