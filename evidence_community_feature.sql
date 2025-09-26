-- Evidence Community Sharing Feature
-- This script adds support for sharing evidence to community

-- Add evidence-related columns to community_messages table
ALTER TABLE community_messages 
ADD COLUMN IF NOT EXISTS is_evidence BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS evidence_category TEXT,
ADD COLUMN IF NOT EXISTS evidence_severity NUMERIC(2,1),
ADD COLUMN IF NOT EXISTS evidence_location TEXT,
ADD COLUMN IF NOT EXISTS evidence_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS evidence_media_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS evidence_tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS evidence_notes TEXT;

-- Create index for evidence posts
CREATE INDEX IF NOT EXISTS idx_community_messages_is_evidence ON community_messages(is_evidence);
CREATE INDEX IF NOT EXISTS idx_community_messages_evidence_category ON community_messages(evidence_category);

-- Create evidence table for storing evidence metadata
CREATE TABLE IF NOT EXISTS evidence (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    severity NUMERIC(2,1) NOT NULL,
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT NOT NULL,
    notes TEXT,
    tags TEXT[] DEFAULT '{}',
    media_urls TEXT[] DEFAULT '{}',
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_shared_to_community BOOLEAN DEFAULT FALSE,
    community_message_id UUID REFERENCES community_messages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for evidence table
CREATE INDEX IF NOT EXISTS idx_evidence_user_id ON evidence(user_id);
CREATE INDEX IF NOT EXISTS idx_evidence_category ON evidence(category);
CREATE INDEX IF NOT EXISTS idx_evidence_incident_date ON evidence(incident_date);
CREATE INDEX IF NOT EXISTS idx_evidence_is_shared_to_community ON evidence(is_shared_to_community);

-- Enable Row Level Security for evidence table
ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for evidence
CREATE POLICY "Users can view their own evidence" ON evidence
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view shared community evidence" ON evidence
    FOR SELECT USING (is_shared_to_community = true);

CREATE POLICY "Users can insert their own evidence" ON evidence
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own evidence" ON evidence
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own evidence" ON evidence
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_evidence_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for evidence table
CREATE TRIGGER update_evidence_updated_at 
    BEFORE UPDATE ON evidence 
    FOR EACH ROW EXECUTE FUNCTION update_evidence_updated_at();

-- Create function to post evidence to community
CREATE OR REPLACE FUNCTION post_evidence_to_community(
    p_user_id UUID,
    p_category TEXT,
    p_severity NUMERIC,
    p_incident_date TIMESTAMP WITH TIME ZONE,
    p_location TEXT,
    p_notes TEXT,
    p_tags TEXT[],
    p_media_count INTEGER,
    p_is_anonymous BOOLEAN DEFAULT FALSE
) RETURNS UUID AS $$
DECLARE
    v_message_id UUID;
    v_user_name TEXT;
    v_user_email TEXT;
    v_summary TEXT;
BEGIN
    -- Get user info
    SELECT 
        COALESCE(raw_user_meta_data->>'full_name', 'Anonymous'),
        email
    INTO v_user_name, v_user_email
    FROM auth.users 
    WHERE id = p_user_id;

    -- Create evidence summary
    v_summary := '📋 Evidence Report\n';
    v_summary := v_summary || 'Category: ' || p_category || '\n';
    v_summary := v_summary || 'Severity: ' || p_severity::TEXT || '/5\n';
    v_summary := v_summary || 'Date: ' || TO_CHAR(p_incident_date, 'Mon DD, YYYY') || ' at ' || TO_CHAR(p_incident_date, 'HH12:MI AM') || '\n';
    v_summary := v_summary || 'Location: ' || p_location || '\n';
    v_summary := v_summary || 'Media: ' || p_media_count::TEXT || ' files attached\n';
    
    IF p_notes IS NOT NULL AND p_notes != '' THEN
        v_summary := v_summary || 'Notes: ' || p_notes || '\n';
    END IF;
    
    IF array_length(p_tags, 1) > 0 THEN
        v_summary := v_summary || 'Tags: ' || array_to_string(p_tags, ', ') || '\n';
    END IF;
    
    v_summary := v_summary || '\nShared from Evidence Upload';

    -- Insert community message
    INSERT INTO community_messages (
        user_id, user_email, user_name, message, 
        is_evidence, evidence_category, evidence_severity, 
        evidence_location, evidence_date, evidence_media_count,
        evidence_tags, evidence_notes
    ) VALUES (
        p_user_id, v_user_email, 
        CASE WHEN p_is_anonymous THEN 'Anonymous' ELSE v_user_name END,
        v_summary, true, p_category, p_severity,
        p_location, p_incident_date, p_media_count,
        p_tags, p_notes
    ) RETURNING id INTO v_message_id;

    RETURN v_message_id;
END;
$$ language 'plpgsql';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION post_evidence_to_community(UUID, TEXT, NUMERIC, TIMESTAMP WITH TIME ZONE, TEXT, TEXT, TEXT[], INTEGER, BOOLEAN) TO authenticated;

-- Insert sample evidence categories for reference
-- These are the categories used in the evidence upload screen
-- 'Harassment', 'Assault', 'Stalking', 'Theft', 'Accident', 'Other'