import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/user_profile_service.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  print('=== SAFRA Profile System Diagnostic ===');
  
  // Test authentication
  final user = Supabase.instance.client.auth.currentUser;
  print('Current user: ${user?.id ?? "Not authenticated"}');
  print('User email: ${user?.email ?? "No email"}');
  
  // Test profile retrieval
  print('\n--- Testing Profile Retrieval ---');
  final profile = await UserProfileService.getUserProfile();
  if (profile != null) {
    print('✅ Profile found:');
    print('  ID: ${profile.id}');
    print('  User ID: ${profile.userId}');
    print('  Name: ${profile.fullName}');
    print('  Phone: ${profile.phoneNumber ?? "Not set"}');
    print('  Bio: ${profile.bio ?? "Not set"}');
    print('  Profile Image: ${profile.profileImageUrl ?? "Not set"}');
  } else {
    print('❌ No profile found or error occurred');
  }
  
  // Test profile creation
  print('\n--- Testing Profile Creation ---');
  if (profile == null && user != null) {
    final newProfile = await UserProfileService.createUserProfile(
      fullName: 'Test User',
      phoneNumber: '+1234567890',
      bio: 'Test bio',
    );
    
    if (newProfile != null) {
      print('✅ Profile created successfully:');
      print('  ID: ${newProfile.id}');
      print('  Name: ${newProfile.fullName}');
    } else {
      print('❌ Failed to create profile');
    }
  } else {
    print('Skipping profile creation (profile already exists or no authenticated user)');
  }
  
  // Test storage bucket
  print('\n--- Testing Storage Bucket ---');
  try {
    final buckets = await Supabase.instance.client.storage.listBuckets();
    print('Available buckets:');
    for (final bucket in buckets) {
      print('  - ${bucket.id} (${bucket.name})');
    }
    
    final hasProfilesBucket = buckets.any((b) => b.id == 'profiles');
    final hasEvidenceBucket = buckets.any((b) => b.id == 'evidence');
    
    print('\nBucket Status:');
    print('  Profiles bucket: ${hasProfilesBucket ? "✅ EXISTS" : "❌ MISSING"}');
    print('  Evidence bucket: ${hasEvidenceBucket ? "✅ EXISTS" : "❌ MISSING"}');
    
  } catch (e) {
    print('❌ Error checking storage buckets: $e');
  }
  
  print('\n=== Diagnostic Complete ===');
}