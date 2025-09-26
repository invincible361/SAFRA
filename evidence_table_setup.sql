-- Evidence table setup for SAFRA
-- This table stores evidence uploads with photo/video URLs

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

-- Enable Row Level Security
ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Users can view their own evidence and community evidence (when shared)
CREATE POLICY "Users can view own evidence" ON evidence
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own evidence
CREATE POLICY "Users can insert own evidence" ON evidence
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own evidence
CREATE POLICY "Users can update own evidence" ON evidence
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own evidence
CREATE POLICY "Users can delete own evidence" ON evidence
    FOR DELETE USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_evidence_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_evidence_updated_at_trigger
    BEFORE UPDATE ON evidence
    FOR EACH ROW
    EXECUTE FUNCTION update_evidence_updated_at();

-- Create function to get evidence with user info
CREATE OR REPLACE FUNCTION get_user_evidence(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    category TEXT,
    severity NUMERIC,
    incident_date TIMESTAMP WITH TIME ZONE,
    location TEXT,
    notes TEXT,
    tags TEXT[],
    photo_urls TEXT[],
    video_urls TEXT[],
    is_anonymous BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    user_email TEXT,
    user_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.category,
        e.severity,
        e.incident_date,
        e.location,
        e.notes,
        e.tags,
        e.photo_urls,
        e.video_urls,
        e.is_anonymous,
        e.created_at,
        u.email::TEXT as user_email,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email::TEXT) as user_name
    FROM evidence e
    JOIN auth.users u ON e.user_id = u.id
    WHERE e.user_id = p_user_id
    ORDER BY e.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_evidence(UUID) TO authenticated;

-- Create storage bucket for evidence files
INSERT INTO storage.buckets (id, name, public) VALUES ('evidence', 'evidence', true);

-- Create storage policies for evidence bucket
-- Allow authenticated users to upload files
CREATE POLICY "Allow authenticated uploads" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'evidence');

-- Allow public read access to evidence files
CREATE POLICY "Allow public read" ON storage.objects
    FOR SELECT USING (bucket_id = 'evidence');

-- Allow users to delete their own files
CREATE POLICY "Allow users to delete own files" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'evidence' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Grant usage on storage
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;