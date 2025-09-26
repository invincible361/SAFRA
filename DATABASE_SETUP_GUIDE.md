# Database Setup Guide for Evidence Upload Feature

## Issue: PostgrestException 404 - Evidence Table Not Found

If you're seeing the error:
```
PostgrestException(message: {}, code: 404, details: Not Found, hint: null)
```

This means the `evidence` table doesn't exist in your Supabase database.

## Solution

### Option 1: Run the SQL Setup Script

1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `evidence_table_setup.sql`
4. Run the SQL script

### Option 2: Use the Setup Script

1. Edit `setup_evidence_table.dart`
2. Replace `your-project.supabase.co` with your actual Supabase URL
3. Replace `your-anon-key` with your actual anon key
4. Run: `dart setup_evidence_table.dart`

### Option 3: Manual Table Creation

If you prefer to create the table manually, here's the essential SQL:

```sql
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

-- Create basic policies
CREATE POLICY "Users can view their own evidence" ON evidence
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own evidence" ON evidence
  FOR INSERT WITH CHECK (auth.uid() = user_id);
'''

## Verification

After setup, the evidence upload should work without the 404 error. The app now includes:

1. **Better error handling** - Clear messages for different error types
2. **Database connection check** - Verifies table exists before inserting
3. **Detailed logging** - Shows exactly what's failing in the console

## Enhanced Error Messages

The app now provides specific error messages:
- **404 errors**: "Evidence table not found. Please run database setup or contact support."
- **403 errors**: "Permission denied. Please check your login status."
- **401 errors**: "Authentication required. Please login again."

## Next Steps

1. Set up the database table using one of the options above
2. Test the evidence upload feature
3. Check the debug console for detailed error information
4. If issues persist, check the full error logs in the console