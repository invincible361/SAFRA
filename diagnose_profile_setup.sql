-- SAFRA Profile Feature Diagnostic Script
-- Run this script to check what parts of the profile setup are missing

-- Check if user_profiles table exists
SELECT 
    'user_profiles table' as component,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles')
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- Check if user_profiles has RLS enabled
SELECT 
    'user_profiles RLS' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'user_profiles'
        )
        THEN 'ENABLED'
        ELSE 'MISSING'
    END as status;

-- Check if profiles storage bucket exists
SELECT 
    'profiles storage bucket' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM storage.buckets WHERE id = 'profiles'
        )
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- Check if evidence storage bucket exists (for comparison)
SELECT 
    'evidence storage bucket' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM storage.buckets WHERE id = 'evidence'
        )
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- Check storage policies for profiles bucket
SELECT 
    'profiles storage policies' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'objects' AND schemaname = 'storage'
            AND policyname LIKE '%profiles%'
        )
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- Check if get_or_create_user_profile function exists
SELECT 
    'get_or_create_user_profile function' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc WHERE proname = 'get_or_create_user_profile'
        )
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- Check current user authentication status
SELECT 
    'current user' as component,
    CASE 
        WHEN auth.uid() IS NOT NULL
        THEN 'AUTHENTICATED: ' || auth.uid()::text
        ELSE 'NOT AUTHENTICATED'
    END as status;

-- Show all storage buckets
SELECT 'Available storage buckets:' as info;
SELECT id, name, public FROM storage.buckets;

-- Show RLS policies for user_profiles table
SELECT 'RLS policies for user_profiles:' as info;
SELECT policyname, cmd, qual::text, with_check::text 
FROM pg_policies 
WHERE tablename = 'user_profiles';