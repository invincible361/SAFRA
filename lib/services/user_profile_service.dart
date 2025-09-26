import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String userId;
  final String? fullName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? profileImageUrl;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime updatedAt;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.profileImageUrl,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.updatedAt,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      userId: map['user_id'],
      fullName: map['full_name'],
      phoneNumber: map['phone_number'],
      dateOfBirth: map['date_of_birth'] != null 
          ? DateTime.parse(map['date_of_birth']) 
          : null,
      gender: map['gender'],
      bio: map['bio'],
      profileImageUrl: map['profile_image_url'],
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      updatedAt: DateTime.parse(map['updated_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserProfileService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Expose current user for convenience
  static User? get currentUser => _supabase.auth.currentUser;

  // Get current user profile
  static Future<UserProfile?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return null;
      }

      print('Fetching profile for user: ${user.id}');
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      print('Profile fetched successfully: ${response['id']}');
      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error getting user profile: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('PostgrestException code: ${e.code}');
        print('PostgrestException message: ${e.message}');
        print('PostgrestException details: ${e.details}');
      }
      return null;
    }
  }

  // Get or create user profile
  static Future<UserProfile?> getOrCreateUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Try to get existing profile first
      UserProfile? profile = await getUserProfile();
      if (profile != null) return profile;

      // Create new profile if it doesn't exist
      final userMetadata = user.userMetadata;
      String fullName = 'User';
      
      if (userMetadata != null) {
        final metadataName = userMetadata['full_name'] as String?;
        if (metadataName != null && metadataName.isNotEmpty) {
          fullName = metadataName;
        } else {
          final firstName = userMetadata['first_name'] as String? ?? '';
          final lastName = userMetadata['last_name'] as String? ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            fullName = '$firstName $lastName'.trim();
          }
        }
      }

      // Fallback to email name
      if (fullName == 'User' && user.email != null && user.email!.isNotEmpty) {
        final emailName = user.email!.split('@').first;
        fullName = emailName.split('.').map((part) => 
          part.isNotEmpty ? '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}' : ''
        ).join(' ').trim();
      }

      final newProfile = await createUserProfile(fullName: fullName);
      return newProfile;
    } catch (e) {
      print('Error getting or creating user profile: $e');
      return null;
    }
  }

  // Create new user profile
  static Future<UserProfile?> createUserProfile({
    required String fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? bio,
    String? profileImageUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No authenticated user for profile creation');
        return null;
      }

      print('Creating profile for user: ${user.id} with name: $fullName');
      
      // Check if profile already exists
      final existingProfile = await getUserProfile();
      if (existingProfile != null) {
        print('Profile already exists for user, returning existing profile');
        return existingProfile;
      }

      final response = await _supabase.from('user_profiles').insert({
        'user_id': user.id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'bio': bio,
        'profile_image_url': profileImageUrl,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
      }).select().single();

      print('Profile created successfully: ${response['id']}');
      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error creating user profile: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('PostgrestException code: ${e.code}');
        print('PostgrestException message: ${e.message}');
        print('PostgrestException details: ${e.details}');
      }
      return null;
    }
  }

  // Update user profile
  static Future<UserProfile?> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? bio,
    String? profileImageUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No authenticated user for profile update');
        return null;
      }

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updateData['gender'] = gender;
      if (bio != null) updateData['bio'] = bio;
      if (profileImageUrl != null) updateData['profile_image_url'] = profileImageUrl;
      if (emergencyContactName != null) updateData['emergency_contact_name'] = emergencyContactName;
      if (emergencyContactPhone != null) updateData['emergency_contact_phone'] = emergencyContactPhone;

      if (updateData.isEmpty) {
        print('No data provided for update');
        return null;
      }

      print('Updating profile for user: ${user.id} with data: $updateData');

      final response = await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      print('Profile updated successfully: ${response['id']}');
      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error updating user profile: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('PostgrestException code: ${e.code}');
        print('PostgrestException message: ${e.message}');
        print('PostgrestException details: ${e.details}');
      }
      return null;
    }
  }

  // Upload profile image
  static Future<String?> uploadProfileImage(String imagePath) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No authenticated user for image upload');
        return null;
      }

      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      print('Uploading profile image: $fileName for user: ${user.id}');
      
      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        print('Image file does not exist: $imagePath');
        return null;
      }

      // Read file bytes
      final fileBytes = await file.readAsBytes();
      
      // Upload to storage using bytes
      final response = await _supabase.storage
          .from('profiles')
          .uploadBinary(fileName, fileBytes);

      print('Image uploaded successfully: $response');

      // Get public URL
      final publicUrl = _supabase.storage
          .from('profiles')
          .getPublicUrl(fileName);

      print('Public URL generated: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      print('Error type: ${e.runtimeType}');
      if (e is StorageException) {
        print('StorageException message: ${e.message}');
        print('StorageException statusCode: ${e.statusCode}');
        print('StorageException error: ${e.error}');
      }
      return null;
    }
  }
}