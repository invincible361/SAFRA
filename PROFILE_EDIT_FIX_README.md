# SAFRA Profile Edit Fix

## Problem Summary
The profile edit functionality was failing due to two main issues:

1. **Missing `user_profiles` table** - The database table was not properly created
2. **Missing `profiles` storage bucket** - The storage bucket for profile images was not created

## Error Messages Seen
```
Error getting user profile: PostgrestException(message: relation "public.user_profiles" does not exist, code: 42P01, details: Not Found, hint: null)
Error creating user profile: PostgrestException(message: {}, code: 404, details: Not Found, hint: null)
Error updating user profile: PostgrestException(message: {}, code: 404, details: Not Found, hint: null)
Error uploading photo 0: StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```

## Solution Files Created

### 1. `fix_complete_profile_setup.sql`
Complete setup script that creates:
- `user_profiles` table with all necessary columns
- Row Level Security (RLS) policies
- `profiles` storage bucket
- Storage policies for profile image uploads
- Helper functions and triggers

### 2. `fix_profile_storage_bucket.sql`
Focused script for just the storage bucket setup if the table already exists.

### 3. `diagnose_profile_setup.sql`
Diagnostic script to check what components are missing.

### 4. Enhanced `user_profile_service.dart`
Improved error handling and debugging output to help identify issues.

## How to Apply the Fix

### Step 1: Run the Diagnostic Script
First, run the diagnostic script to see what's missing:
```sql
-- Copy and run the contents of diagnose_profile_setup.sql in your Supabase SQL editor
```

### Step 2: Apply the Complete Fix
Run the complete setup script:
```sql
-- Copy and run the contents of fix_complete_profile_setup.sql in your Supabase SQL editor
```

### Step 3: Verify the Fix
Run the diagnostic script again to confirm everything is set up correctly.

## Enhanced Error Handling
The `UserProfileService` now includes:
- Detailed error logging with specific error types
- Better null checking and validation
- File existence checks before upload
- Duplicate profile prevention
- More informative debug messages

## Testing the Fix
After applying the SQL scripts, you can test the profile functionality:

1. **Check if profile can be retrieved:**
   ```dart
   final profile = await UserProfileService.getUserProfile();
   print('Profile: $profile');
   ```

2. **Test profile creation:**
   ```dart
   final profile = await UserProfileService.createUserProfile(
     fullName: 'Test User',
     phoneNumber: '+1234567890',
   );
   ```

3. **Test profile image upload:**
   ```dart
   final imageUrl = await UserProfileService.uploadProfileImage('/path/to/image.jpg');
   print('Image URL: $imageUrl');
   ```

## Storage Buckets
The fix creates two storage buckets:
- `evidence` - For evidence uploads (already existed)
- `profiles` - For user profile images (newly created)

## Security Features
- Row Level Security ensures users can only access their own profiles
- Storage policies control who can upload/read/delete profile images
- Automatic cleanup of old profile images when users update their photos

## Troubleshooting
If you still see errors after applying the fix:

1. Check the detailed error messages in the console
2. Run the diagnostic script to verify setup
3. Ensure you're authenticated before trying profile operations
4. Check that your Supabase project has storage enabled
5. Verify your Supabase configuration in the Flutter app