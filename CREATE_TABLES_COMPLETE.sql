-- SAFRA Complete Database Table Creation Script
-- Enhanced 4-Level Table Structure with Relationships

-- =====================================================
-- LEVEL 1: CORE USER DATA (FOUNDATION)
-- =====================================================

-- User Profiles Table - Stores editable user information
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    full_name TEXT,
    phone_number TEXT CHECK (phone_number ~ '^\+?[1-9]\d{1,14}$' OR phone_number IS NULL),
    date_of_birth DATE CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '13 years'),
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    bio TEXT CHECK (LENGTH(bio) <= 500),
    profile_image_url TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT CHECK (emergency_contact_phone ~ '^\+?[1-9]\d{1,14}$' OR emergency_contact_phone IS NULL),
    language_preference TEXT DEFAULT 'en' CHECK (language_preference IN ('en', 'hi', 'kn')),
    safety_status TEXT DEFAULT 'safe' CHECK (safety_status IN ('safe', 'unsafe', 'emergency')),
    last_location TEXT,
    last_location_updated_at TIMESTAMP WITH TIME ZONE,
    is_profile_complete BOOLEAN DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Settings Table - User preferences and configurations
CREATE TABLE IF NOT EXISTS user_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    biometric_enabled BOOLEAN DEFAULT false,
    location_sharing_enabled BOOLEAN DEFAULT true,
    emergency_sms_enabled BOOLEAN DEFAULT true,
    community_notifications BOOLEAN DEFAULT true,
    evidence_backup_enabled BOOLEAN DEFAULT true,
    theme_preference TEXT DEFAULT 'light' CHECK (theme_preference IN ('light', 'dark', 'auto')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- LEVEL 2: EVIDENCE & INCIDENT DATA
-- =====================================================

-- Evidence Table - Stores incident reports and evidence
CREATE TABLE IF NOT EXISTS evidence (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    incident_title TEXT NOT NULL CHECK (LENGTH(incident_title) <= 200),
    category TEXT NOT NULL CHECK (category IN ('Harassment', 'Assault', 'Stalking', 'Theft', 'Accident', 'Vandalism', 'Other')),
    severity NUMERIC(2,1) NOT NULL CHECK (severity >= 1.0 AND severity <= 5.0),
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL CHECK (incident_date <= CURRENT_TIMESTAMP),
    location TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_accuracy DECIMAL(5, 2),
    notes TEXT CHECK (LENGTH(notes) <= 1000),
    tags TEXT[],
    photo_urls TEXT[],
    video_urls TEXT[],
    audio_urls TEXT[],
    document_urls TEXT[],
    is_anonymous BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    verification_notes TEXT,
    case_status TEXT DEFAULT 'open' CHECK (case_status IN ('open', 'in_progress', 'closed', 'dismissed')),
    police_station TEXT,
    fir_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Evidence Metadata Table - Additional evidence details
CREATE TABLE IF NOT EXISTS evidence_metadata (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    evidence_id UUID NOT NULL REFERENCES evidence(id) ON DELETE CASCADE,
    device_info JSONB,
    weather_conditions TEXT,
    lighting_conditions TEXT CHECK (lighting_conditions IN ('daylight', 'dusk', 'night', 'artificial')),
    crowd_density TEXT CHECK (crowd_density IN ('empty', 'sparse', 'moderate', 'crowded')),
    safety_level TEXT CHECK (safety_level IN ('safe', 'moderate', 'unsafe', 'dangerous')),
    witness_count INTEGER DEFAULT 0,
    police_response_time INTERVAL,
    medical_attention_required BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- LEVEL 3: COMMUNITY & SOCIAL DATA
-- =====================================================

-- Community Messages Table - Public community interactions
CREATE TABLE IF NOT EXISTS community_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_email TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_avatar_url TEXT,
    message TEXT NOT NULL CHECK (LENGTH(message) <= 500),
    message_type TEXT DEFAULT 'general' CHECK (message_type IN ('general', 'alert', 'safety_tip', 'emergency')),
    severity_level TEXT DEFAULT 'info' CHECK (severity_level IN ('info', 'warning', 'danger')),
    location_hint TEXT,
    is_verified BOOLEAN DEFAULT false,
    likes_count INTEGER DEFAULT 0,
    replies_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMP WITH TIME ZONE,
    parent_message_id UUID REFERENCES community_messages(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Community Reports Table - Anonymous safety reports
CREATE TABLE IF NOT EXISTS community_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    report_type TEXT NOT NULL CHECK (report_type IN ('suspicious_activity', 'safety_hazard', 'emergency', 'crime', 'other')),
    title TEXT NOT NULL CHECK (LENGTH(title) <= 150),
    description TEXT NOT NULL CHECK (LENGTH(description) <= 1000),
    location TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    urgency TEXT CHECK (urgency IN ('low', 'medium', 'high', 'critical')),
    image_urls TEXT[],
    is_anonymous BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    verification_source TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected', 'expired')),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- LEVEL 4: SYSTEM & UTILITY DATA
-- =====================================================

-- Emergency Contacts Table - User's emergency contact list
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    contact_name TEXT NOT NULL CHECK (LENGTH(contact_name) <= 100),
    contact_phone TEXT NOT NULL CHECK (contact_phone ~ '^\+?[1-9]\d{1,14}$'),
    contact_email TEXT CHECK (contact_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR contact_email IS NULL),
    relationship TEXT CHECK (LENGTH(relationship) <= 50),
    priority_order INTEGER DEFAULT 1 CHECK (priority_order >= 1 AND priority_order <= 5),
    is_active BOOLEAN DEFAULT true,
    last_notified_at TIMESTAMP WITH TIME ZONE,
    notification_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, contact_phone)
);

-- SOS History Table - Track SOS activations
CREATE TABLE IF NOT EXISTS sos_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activation_method TEXT CHECK (activation_method IN ('app_button', 'hardware_button', 'voice_command', 'shake_gesture')),
    location TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_accuracy DECIMAL(5, 2),
    contacts_notified INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    response_received BOOLEAN DEFAULT false,
    response_time INTERVAL,
    notes TEXT CHECK (LENGTH(notes) <= 500),
    is_test BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Location History Table - Track user locations for safety
CREATE TABLE IF NOT EXISTS location_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    location TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    altitude DECIMAL(8, 2),
    accuracy DECIMAL(5, 2),
    speed DECIMAL(6, 2),
    heading DECIMAL(6, 2),
    provider TEXT CHECK (provider IN ('gps', 'network', 'wifi', 'cell')),
    battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
    is_safe_location BOOLEAN DEFAULT true,
    safety_notes TEXT CHECK (LENGTH(safety_notes) <= 200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- SECURITY & ACCESS CONTROL
-- =====================================================

-- Enable Row Level Security for all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE sos_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_history ENABLE ROW LEVEL SECURITY;

-- User Profiles RLS Policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- User Settings RLS Policies
CREATE POLICY "Users can manage their own settings" ON user_settings
    USING (auth.uid() = user_id);

-- Evidence RLS Policies
CREATE POLICY "Users can view their own evidence" ON evidence
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own evidence" ON evidence
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own evidence" ON evidence
    FOR UPDATE USING (auth.uid() = user_id);

-- Evidence Metadata RLS Policies
CREATE POLICY "Users can manage their evidence metadata" ON evidence_metadata
    USING (auth.uid() = evidence_metadata.evidence_id::UUID IN (SELECT id FROM evidence WHERE user_id = auth.uid()));

-- Community Messages RLS Policies
CREATE POLICY "Users can view all community messages" ON community_messages
    FOR SELECT USING (true);
CREATE POLICY "Users can insert their own messages" ON community_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own messages" ON community_messages
    FOR UPDATE USING (auth.uid() = user_id);

-- Community Reports RLS Policies
CREATE POLICY "Users can view all verified reports" ON community_reports
    FOR SELECT USING (is_verified = true OR user_id = auth.uid());
CREATE POLICY "Users can insert their own reports" ON community_reports
    FOR INSERT WITH CHECK (auth.uid() = user_id OR is_anonymous = true);

-- Emergency Contacts RLS Policies
CREATE POLICY "Users can manage their emergency contacts" ON emergency_contacts
    USING (auth.uid() = user_id);

-- SOS History RLS Policies
CREATE POLICY "Users can view their own SOS history" ON sos_history
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert SOS records" ON sos_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Location History RLS Policies
CREATE POLICY "Users can manage their location history" ON location_history
    USING (auth.uid() = user_id);

-- =====================================================
-- TRIGGERS & FUNCTIONS
-- =====================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to get or create user profile
CREATE OR REPLACE FUNCTION get_or_create_user_profile()
RETURNS user_profiles AS $$
DECLARE
    profile_record user_profiles;
BEGIN
    SELECT * INTO profile_record 
    FROM user_profiles 
    WHERE user_id = auth.uid();
    
    IF NOT FOUND THEN
        INSERT INTO user_profiles (user_id, full_name)
        VALUES (auth.uid(), auth.users()->full_name)
        RETURNING * INTO profile_record;
    END IF;
    
    RETURN profile_record;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Function to update profile completeness
CREATE OR REPLACE FUNCTION update_profile_completeness()
RETURNS TRIGGER AS $$
BEGIN
    NEW.is_profile_complete := (
        NEW.full_name IS NOT NULL AND 
        NEW.phone_number IS NOT NULL AND 
        NEW.date_of_birth IS NOT NULL
    );
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at 
    BEFORE UPDATE ON user_settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_evidence_updated_at_trigger
    BEFORE UPDATE ON evidence
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_community_reports_updated_at_trigger
    BEFORE UPDATE ON community_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_contacts_updated_at_trigger
    BEFORE UPDATE ON emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profile_completeness_trigger
    BEFORE INSERT OR UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_profile_completeness();

-- =====================================================
-- STORAGE & FILE MANAGEMENT
-- =====================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('evidence', 'evidence', true),
    ('profiles', 'profiles', true),
    ('community', 'community', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for evidence bucket
CREATE POLICY "Allow authenticated uploads to evidence" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'evidence');

CREATE POLICY "Allow public read access to evidence" ON storage.objects
    FOR SELECT USING (bucket_id = 'evidence');

CREATE POLICY "Allow users to delete own evidence files" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'evidence' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Storage policies for profiles bucket
CREATE POLICY "Allow authenticated uploads to profiles" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'profiles');

CREATE POLICY "Allow public read access to profiles" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

CREATE POLICY "Allow users to delete own profile files" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'profiles' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- =====================================================
-- INDEXES & PERFORMANCE OPTIMIZATION
-- =====================================================

-- User Profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles(updated_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_safety_status ON user_profiles(safety_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_location_updated ON user_profiles(last_location_updated_at);

-- User Settings indexes
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);

-- Evidence indexes
CREATE INDEX IF NOT EXISTS idx_evidence_user_id ON evidence(user_id);
CREATE INDEX IF NOT EXISTS idx_evidence_created_at ON evidence(created_at);
CREATE INDEX IF NOT EXISTS idx_evidence_category ON evidence(category);
CREATE INDEX IF NOT EXISTS idx_evidence_severity ON evidence(severity);
CREATE INDEX IF NOT EXISTS idx_evidence_case_status ON evidence(case_status);
CREATE INDEX IF NOT EXISTS idx_evidence_location ON evidence USING GIN(location);

-- Evidence Metadata indexes
CREATE INDEX IF NOT EXISTS idx_evidence_metadata_evidence_id ON evidence_metadata(evidence_id);

-- Community Messages indexes
CREATE INDEX IF NOT EXISTS idx_community_messages_created_at ON community_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_community_messages_user_id ON community_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_community_messages_type ON community_messages(message_type);
CREATE INDEX IF NOT EXISTS idx_community_messages_severity ON community_messages(severity_level);
CREATE INDEX IF NOT EXISTS idx_community_messages_parent ON community_messages(parent_message_id);

-- Community Reports indexes
CREATE INDEX IF NOT EXISTS idx_community_reports_created_at ON community_reports(created_at);
CREATE INDEX IF NOT EXISTS idx_community_reports_type ON community_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_community_reports_status ON community_reports(status);
CREATE INDEX IF NOT EXISTS idx_community_reports_severity ON community_reports(severity);

-- Emergency Contacts indexes
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_priority ON emergency_contacts(priority_order);

-- SOS History indexes
CREATE INDEX IF NOT EXISTS idx_sos_history_user_id ON sos_history(user_id);
CREATE INDEX IF NOT EXISTS idx_sos_history_created_at ON sos_history(created_at);
CREATE INDEX IF NOT EXISTS idx_sos_history_method ON sos_history(activation_method);

-- Location History indexes
CREATE INDEX IF NOT EXISTS idx_location_history_user_id ON location_history(user_id);
CREATE INDEX IF NOT EXISTS idx_location_history_created_at ON location_history(created_at);
CREATE INDEX IF NOT EXISTS idx_location_history_coordinates ON location_history(latitude, longitude);

-- =====================================================
-- GRANTS & PERMISSIONS
-- =====================================================

-- Grant permissions to authenticated users
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON user_settings TO authenticated;
GRANT ALL ON evidence TO authenticated;
GRANT ALL ON evidence_metadata TO authenticated;
GRANT ALL ON community_messages TO authenticated;
GRANT ALL ON community_reports TO authenticated;
GRANT ALL ON emergency_contacts TO authenticated;
GRANT ALL ON sos_history TO authenticated;
GRANT ALL ON location_history TO authenticated;

-- Grant function execution permissions
GRANT EXECUTE ON FUNCTION get_or_create_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION update_updated_at_column() TO authenticated;

-- Grant storage permissions
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA auth TO authenticated;

-- =====================================================
-- SAMPLE DATA (Optional - Uncomment to add test data)
-- =====================================================

-- INSERT INTO community_messages (user_id, user_email, user_name, message, message_type, severity_level) VALUES
-- (gen_random_uuid(), 'safety@example.com', 'Safety Bot', 'Welcome to SAFRA Community! Stay safe and look out for each other.', 'safety_tip', 'info');

-- INSERT INTO community_reports (user_id, report_type, title, description, location, latitude, longitude, severity, urgency) VALUES
-- (gen_random_uuid(), 'safety_hazard', 'Broken Street Light', 'Street light on Main St is broken, making the area unsafe at night', 'Main St, Bangalore', 12.9716, 77.5946, 'medium', 'medium');

-- Final success message
SELECT 'SAFRA Database Tables Created Successfully!' as status;