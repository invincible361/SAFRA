import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:safra_app/services/user_profile_service.dart';
import 'edit_profile_screen.dart';
import '../../../config/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserProfileService.getOrCreateUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          // Load profile image if URL exists
          if (profile?.profileImageUrl != null && profile!.profileImageUrl!.isNotEmpty) {
            _profileImage = null; // Will use NetworkImage instead
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });
        
        // Upload the image to Supabase storage
        final uploadedImageUrl = await UserProfileService.uploadProfileImage(pickedFile.path);
        
        if (uploadedImageUrl != null) {
          // Update the user profile with the new image URL
          final updatedProfile = await UserProfileService.updateUserProfile(
            profileImageUrl: uploadedImageUrl,
          );
          
          if (updatedProfile != null) {
            setState(() {
              _profileImage = File(pickedFile.path);
              _userProfile = updatedProfile; // Update the profile with new image URL
              _isUploading = false;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile image updated successfully!")),
              );
          }
          } else {
            setState(() {
              _isUploading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to update profile in database")),
              );
            }
          }
        } else {
          setState(() {
            _isUploading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to upload image")),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile image: $e")),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Changed to opaque white
          title: const Text(
            "Choose Image Source",
            style: TextStyle(color: Colors.black), // Changed to black text
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryAccent),
                title: const Text("Camera", style: TextStyle(color: Colors.black)), // Changed to black text
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryAccent),
                title: const Text("Gallery", style: TextStyle(color: Colors.black)), // Changed to black text
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)), // Changed to grey text
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryAccent,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, "User Profile"),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Picture Section
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryAccent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryAccent.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: AppColors.glassBackground,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (_userProfile?.profileImageUrl != null && _userProfile!.profileImageUrl!.isNotEmpty)
                                        ? NetworkImage(_userProfile!.profileImageUrl!)
                                        : const AssetImage('assets/logo.png'),
                                child: _isUploading
                                    ? const CircularProgressIndicator(
                                        color: AppColors.primaryAccent,
                                        strokeWidth: 2,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.glassBackground,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // User Information
                      _buildInfoCard(
                        "Personal Information",
                        [
                          _buildInfoRow("Full Name", _userProfile?.fullName ?? 'Loading...'),
                          _buildInfoRow("Email", _getUserEmail()),
                          _buildInfoRow("Phone", _userProfile?.phoneNumber ?? 'Not set'),
                          _buildInfoRow("Date of Birth", _formatDateOfBirth()),
                          _buildInfoRow("Gender", _userProfile?.gender ?? 'Not set'),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Account Information
                      _buildInfoCard(
                        "Account Information",
                        [
                          _buildInfoRow("Member Since", _formatMemberSince()),
                          _buildInfoRow("Account Type", "Standard"),
                          _buildInfoRow("Verification Status", _getVerificationStatus(), valueColor: _getVerificationColor()),
                          _buildInfoRow("Emergency Contact", _userProfile?.emergencyContactName ?? 'Not set'),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      _buildActionButton(
                        context,
                        "Edit Profile",
                        Icons.edit,
                        () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          // Reload profile if it was updated
                          if (result == true) {
                            _loadUserProfile();
                          }
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        context,
                        "Change Password",
                        Icons.lock,
                        () {
                          // TODO: Implement change password functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Change Password feature coming soon!")),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        context,
                        "Privacy Settings",
                        Icons.privacy_tip,
                        () {
                          // TODO: Navigate to privacy settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Privacy Settings feature coming soon!")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserEmail() {
    final user = UserProfileService.currentUser;
    return user?.email ?? 'Not available';
  }

  String _formatDateOfBirth() {
    if (_userProfile?.dateOfBirth == null) return 'Not set';
    return '${_userProfile!.dateOfBirth!.day}/${_userProfile!.dateOfBirth!.month}/${_userProfile!.dateOfBirth!.year}';
  }

  String _formatMemberSince() {
    final user = UserProfileService.currentUser;
    if (user == null) return 'Unknown';
    // Use the user profile creation date instead of auth user date
    if (_userProfile?.createdAt == null) return 'Recently';
    final createdDate = _userProfile!.createdAt;
    return '${createdDate.day}/${createdDate.month}/${createdDate.year}';
  }

  String _getVerificationStatus() {
    // For now, return basic status based on email verification
    final user = UserProfileService.currentUser;
    if (user?.emailConfirmedAt != null) return 'Verified';
    return 'Pending';
  }

  Color _getVerificationColor() {
    final user = UserProfileService.currentUser;
    if (user?.emailConfirmedAt != null) return Colors.green;
    return Colors.orange;
  }
}