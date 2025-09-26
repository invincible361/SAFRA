import 'dart:async';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/sms_service.dart';
import '../services/user_profile_service.dart';
import '../config/app_colors.dart';
import 'contact_selection_screen.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  int countdown = 5;
  Timer? timer;
  bool isPressed = false;
  bool sosTriggered = false;
  Contact? selectedContact;
  LatLng? currentLocation;
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadEmergencyContact();
  }

  Future<void> _loadEmergencyContact() async {
    try {
      final userProfile = await UserProfileService.getUserProfile();
      if (userProfile != null && 
          userProfile.emergencyContactName != null && 
          userProfile.emergencyContactPhone != null) {
        // Create a contact from the profile emergency contact
        final emergencyContact = Contact(
          displayName: userProfile.emergencyContactName,
          phones: [Item(label: 'mobile', value: userProfile.emergencyContactPhone)],
        );
        
        if (mounted) {
          setState(() {
            selectedContact = emergencyContact;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency contact loaded from profile: ${userProfile.emergencyContactName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading emergency contact: $e');
      // If no emergency contact in profile, user can still select from contact book
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void startTimer() {
    if (selectedContact == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set an emergency contact in your profile or select one from your contact book'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (currentLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      isPressed = true;
      countdown = 5;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
      } else {
        t.cancel();
        triggerSOS();
      }
    });
  }

  Future<void> triggerSOS() async {
    setState(() {
      sosTriggered = true;
    });

    try {
      if (selectedContact != null && currentLocation != null) {
        // Get the first phone number from the selected contact
        String? phoneNumber = selectedContact!.phones?.firstOrNull?.value;
        
        if (phoneNumber != null) {
          // Send SOS message with location
          bool success = await SmsService.shareLocationViaSms(
            phoneNumber: phoneNumber,
            customMessage: '🚨 SOS ALERT! I need immediate help! My current location:',
            customLocation: currentLocation,
          );

          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚨 SOS Alert sent to ${selectedContact!.displayName ?? 'Contact'}!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to send SOS alert. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected contact has no phone number'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending SOS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectContact() async {
    final Contact? contact = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (context) => ContactSelectionScreen(
          onContactSelected: (Contact contact) {
            Navigator.pop(context, contact);
          },
        ),
      ),
    );

    if (contact != null) {
      setState(() {
        selectedContact = contact;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Emergency SOS',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
                    // Content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Contact Selection Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.glassBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.glassBorder,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                selectedContact != null ? 'Emergency Contact' : 'Select Emergency Contact',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (selectedContact != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.success,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, color: AppColors.success),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedContact!.displayName ?? 'Unknown',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.primaryAccent),
                                        onPressed: _selectContact,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _selectContact,
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Select from Contact Book'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Location Status
                        if (isLoadingLocation)
                          const CircularProgressIndicator(color: AppColors.primaryAccent)
                        else if (currentLocation != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success,
                              width: 1,
                            ),
                          ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: AppColors.success),
                                SizedBox(width: 8),
                                Text(
                                  'Location Available',
                                  style: TextStyle(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_off, color: AppColors.error),
                                SizedBox(width: 8),
                                Text(
                                  'Location Unavailable',
                                  style: TextStyle(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 30),

                        Text(
                          isPressed ? "Timer : 00 : 0$countdown sec" : "Press Button",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // SOS Button
                        GestureDetector(
                          onTap: () {
                            if (!isPressed) {
                              startTimer();
                            }
                          },
                          child: Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              color: selectedContact != null && currentLocation != null
                                  ? AppColors.error
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "EMERGENCY\nSOS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        if (!sosTriggered)
                          Text(
                            "After pressing the button\nEmergency Alert will be triggered\nin next 5 sec",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),

                        if (sosTriggered)
                          const Text(
                            "🚨 Emergency SOS Triggered!",
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
