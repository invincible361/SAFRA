import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://your-project.supabase.co', // Replace with your Supabase URL
      anonKey: 'your-anon-key', // Replace with your anon key
    );

    final client = Supabase.instance.client;

    print('Setting up evidence table...');

    // Create evidence table
    final createTableSQL = '''
    CREATE TABLE IF NOT EXISTS evidence (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
      category TEXT NOT NULL,
      severity NUMERIC(2,1) NOT NULL CHECK (severity >= 0 AND severity <= 5),
      incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
      location TEXT NOT NULL,
      notes TEXT,
      tags TEXT[],
      photo_urls TEXT[],
      video_urls TEXT[],
      is_anonymous BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
    );

    -- Enable Row Level Security
    ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;

    -- Create policies
    CREATE POLICY "Users can view their own evidence" ON evidence
      FOR SELECT USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own evidence" ON evidence
      FOR INSERT WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own evidence" ON evidence
      FOR UPDATE USING (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own evidence" ON evidence
      FOR DELETE USING (auth.uid() = user_id);

    -- Create updated_at trigger
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS \$\$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    \$\$ LANGUAGE plpgsql;

    CREATE TRIGGER update_evidence_updated_at
      BEFORE UPDATE ON evidence
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();

    -- Create function to get user's evidence
    CREATE OR REPLACE FUNCTION get_user_evidence(user_uuid UUID)
    RETURNS SETOF evidence AS \$\$
    BEGIN
      RETURN QUERY
      SELECT * FROM evidence
      WHERE user_id = user_uuid
      ORDER BY created_at DESC;
    END;
    \$\$ LANGUAGE plpgsql SECURITY DEFINER;

    -- Create storage bucket for evidence files
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('evidence', 'evidence', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'video/quicktime'])
    ON CONFLICT (id) DO NOTHING;

    -- Create storage policies
    CREATE POLICY "Users can upload their own evidence files" ON storage.objects
      FOR INSERT WITH CHECK (
        bucket_id = 'evidence' AND
        auth.uid()::text = (storage.foldername(name))[1]
      );

    CREATE POLICY "Users can view evidence files" ON storage.objects
      FOR SELECT USING (bucket_id = 'evidence');

    CREATE POLICY "Users can update their own evidence files" ON storage.objects
      FOR UPDATE USING (
        bucket_id = 'evidence' AND
        auth.uid()::text = (storage.foldername(name))[1]
      );

    CREATE POLICY "Users can delete their own evidence files" ON storage.objects
      FOR DELETE USING (
        bucket_id = 'evidence' AND
        auth.uid()::text = (storage.foldername(name))[1]
      );
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': createTableSQL});
      print('Evidence table setup completed successfully!');
    } catch (e) {
      print('Error setting up evidence table: $e');
      print('You may need to run this SQL manually in your Supabase dashboard.');
    }

  } catch (e) {
    print('Error initializing Supabase: $e');
    print('Make sure to replace the Supabase URL and anon key with your actual values.');
  }
}