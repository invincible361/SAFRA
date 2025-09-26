-- Add media URL columns to community_messages table
-- Run this script in your Supabase SQL editor

-- Add columns for evidence photo and video URLs
ALTER TABLE community_messages 
ADD COLUMN IF NOT EXISTS evidence_photo_urls TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS evidence_video_urls TEXT[] DEFAULT '{}';

-- Create indexes for better performance with evidence media
CREATE INDEX IF NOT EXISTS idx_community_messages_evidence_photos ON community_messages USING GIN (evidence_photo_urls);
CREATE INDEX IF NOT EXISTS idx_community_messages_evidence_videos ON community_messages USING GIN (evidence_video_urls);

-- Update the post_evidence_to_community function to handle media URLs
CREATE OR REPLACE FUNCTION post_evidence_to_community(
    p_user_id UUID,
    p_user_email TEXT,
    p_user_name TEXT,
    p_category TEXT,
    p_severity NUMERIC,
    p_location TEXT,
    p_incident_date TIMESTAMP WITH TIME ZONE,
    p_media_count INTEGER,
    p_tags TEXT[],
    p_notes TEXT,
    p_photo_urls TEXT[] DEFAULT '{}',
    p_video_urls TEXT[] DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    message_id UUID;
BEGIN
    -- Insert the evidence post into community_messages
    INSERT INTO community_messages (
        user_id,
        user_email,
        user_name,
        message,
        is_evidence,
        evidence_category,
        evidence_severity,
        evidence_location,
        evidence_date,
        evidence_media_count,
        evidence_tags,
        evidence_notes,
        evidence_photo_urls,
        evidence_video_urls
    ) VALUES (
        p_user_id,
        p_user_email,
        p_user_name,
        'Shared evidence: ' || p_category || ' incident at ' || p_location,
        true,
        p_category,
        p_severity,
        p_location,
        p_incident_date,
        p_media_count,
        p_tags,
        p_notes,
        p_photo_urls,
        p_video_urls
    ) RETURNING id INTO message_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql;