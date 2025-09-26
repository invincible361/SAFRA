-- SAFRA Community and DigiLocker Database Setup
-- Run this script in your Supabase SQL editor

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

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

-- Create digilocker_sessions table
CREATE TABLE IF NOT EXISTS digilocker_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    state TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create digilocker_tokens table
CREATE TABLE IF NOT EXISTS digilocker_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    expires_in INTEGER,
    state TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_aadhaar table
CREATE TABLE IF NOT EXISTS user_aadhaar (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    aadhaar_number TEXT NOT NULL,
    name TEXT NOT NULL,
    date_of_birth DATE,
    gender TEXT,
    address TEXT,
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_aadhaar_user_id ON user_aadhaar(user_id);
CREATE INDEX IF NOT EXISTS idx_user_aadhaar_verified ON user_aadhaar(verified);

-- Enable Row Level Security (RLS)
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE digilocker_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE digilocker_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_aadhaar ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for community_messages
CREATE POLICY "Users can view all community messages" ON community_messages
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert messages" ON community_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own messages" ON community_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" ON community_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for digilocker_sessions
CREATE POLICY "Users can view their own sessions" ON digilocker_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sessions" ON digilocker_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sessions" ON digilocker_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for digilocker_tokens
CREATE POLICY "Users can view their own tokens" ON digilocker_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tokens" ON digilocker_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tokens" ON digilocker_tokens
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tokens" ON digilocker_tokens
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for user_aadhaar
CREATE POLICY "Users can view their own aadhaar data" ON user_aadhaar
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own aadhaar data" ON user_aadhaar
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own aadhaar data" ON user_aadhaar
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own aadhaar data" ON user_aadhaar
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for digilocker_tokens table
CREATE TRIGGER update_digilocker_tokens_updated_at 
    BEFORE UPDATE ON digilocker_tokens 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to clean up expired sessions (optional)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
    DELETE FROM digilocker_sessions 
    WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$ language 'plpgsql';

-- Create a view for user verification status
CREATE OR REPLACE VIEW user_verification_status AS
SELECT 
    u.id as user_id,
    u.email,
    u.email_confirmed_at IS NOT NULL as google_verified,
    COALESCE(ua.verified, false) as aadhaar_verified,
    ua.aadhaar_number,
    ua.name as aadhaar_name,
    ua.verified_at as aadhaar_verified_at
FROM auth.users u
LEFT JOIN user_aadhaar ua ON u.id = ua.user_id;

-- Grant access to the view
GRANT SELECT ON user_verification_status TO authenticated;

-- Insert some sample data for testing (optional)
-- INSERT INTO community_messages (user_id, user_email, user_name, message) VALUES
-- (auth.uid(), 'test@example.com', 'Test User', 'Welcome to SAFRA Community!');

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_community_messages_user_email ON community_messages(user_email);
CREATE INDEX IF NOT EXISTS idx_digilocker_tokens_user_id ON digilocker_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_aadhaar_aadhaar_number ON user_aadhaar(aadhaar_number);

-- Create a function to get community statistics
CREATE OR REPLACE FUNCTION get_community_stats()
RETURNS TABLE (
    total_messages BIGINT,
    total_users BIGINT,
    verified_users BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM community_messages) as total_messages,
        (SELECT COUNT(DISTINCT user_id) FROM community_messages) as total_users,
        (SELECT COUNT(*) FROM user_aadhaar WHERE verified = true) as verified_users;
END;
$$ language 'plpgsql';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_community_stats() TO authenticated;
