import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> moreOptions = const [
    {"icon": Icons.help_outline, "title": "Help"},
    {"icon": Icons.safety_check_outlined, "title": "Safety Tips"},
    {"icon": Icons.settings, "title": "Settings"},
    {"icon": Icons.info_outline, "title": "About"},
  ];

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
                    const SizedBox(width: 12),
                    const Text(
                      "More Options",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Options List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: moreOptions.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.glassBorder,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Icon(
                          moreOptions[index]["icon"], 
                          color: AppColors.primaryAccent,
                          size: 28,
                        ),
                        title: Text(
                          moreOptions[index]["title"],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios, 
                          color: AppColors.textSecondary, 
                          size: 16
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubOptionScreen(
                                title: moreOptions[index]["title"],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubOptionScreen extends StatelessWidget {
  final String title;
  const SubOptionScreen({Key? key, required this.title}) : super(key: key);

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
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String title) {
    switch (title) {
      case "Help":
        return _buildHelpContent();
      case "Safety Tips":
        return _buildSafetyTipsContent();
      case "Settings":
        return _buildSettingsContent();
      case "About":
        return _buildAboutContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHelpContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          "How to Use SAFRA",
          [
            "• Open the app and sign in with your Google account",
            "• Use the SOS button for emergency situations",
            "• Share your location with trusted contacts",
            "• Navigate safely using the built-in maps",
            "• Access community support and safety tips",
          ],
          Icons.phone_android,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Emergency Features",
          [
            "• SOS Button: Press and hold for 3 seconds to send emergency alert",
            "• Location Sharing: Automatically shares your location with selected contacts",
            "• Quick Access: Easy access to emergency services",
            "• Silent Mode: Discreet emergency alerts",
          ],
          Icons.emergency,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Contact Support",
          [
            "• Email: support@safra-app.com",
            "• Emergency: 100 (Police)",
            "• Women Helpline: 1091",
            "• Domestic Violence: 181",
          ],
          Icons.support_agent,
        ),
      ],
    );
  }

  Widget _buildSafetyTipsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          "Personal Safety",
          [
            "• Always be aware of your surroundings",
            "• Trust your instincts - if something feels wrong, it probably is",
            "• Keep your phone charged and easily accessible",
            "• Share your location with trusted friends/family",
            "• Avoid isolated areas, especially at night",
          ],
          Icons.person_pin,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Travel Safety",
          [
            "• Plan your route in advance",
            "• Use well-lit and populated streets",
            "• Avoid shortcuts through dark alleys",
            "• Keep emergency contacts on speed dial",
            "• Share your travel plans with someone",
          ],
          Icons.directions_walk,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Public Transport",
          [
            "• Sit near the driver or in well-lit areas",
            "• Avoid empty train cars or bus sections",
            "• Keep your belongings close to you",
            "• Be aware of who gets on/off with you",
            "• Have your phone ready for emergency calls",
          ],
          Icons.directions_bus,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Digital Safety",
          [
            "• Never share your exact location on social media",
            "• Be cautious with location-based apps",
            "• Regularly update your privacy settings",
            "• Don't share personal information with strangers",
            "• Use strong, unique passwords",
          ],
          Icons.security,
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          "Privacy & Security",
          [
            "• Location Services: Control when app can access location",
            "• Contact Access: Manage which contacts can receive alerts",
            "• Biometric Lock: Enable Face ID/Touch ID for app access",
            "• PIN Protection: Set a PIN code for additional security",
            "• Data Sharing: Control what information is shared",
          ],
          Icons.privacy_tip,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Notifications",
          [
            "• Emergency Alerts: Receive immediate emergency notifications",
            "• Safety Reminders: Get periodic safety tips and reminders",
            "• Location Updates: Notify when location is shared",
            "• Community Updates: Stay informed about local safety",
            "• Sound & Vibration: Customize alert preferences",
          ],
          Icons.notifications_active,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "App Preferences",
          [
            "• Language: Choose your preferred language",
            "• Theme: Light/Dark mode selection",
            "• Units: Metric/Imperial measurements",
            "• Auto-lock: Set app auto-lock timer",
            "• Backup: Enable/disable data backup",
          ],
          Icons.tune,
        ),
      ],
    );
  }

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          "About SAFRA",
          [
            "SAFRA is a comprehensive women safety application designed to provide immediate assistance and support in emergency situations.",
            "",
            "Our mission is to create a safer environment for women by leveraging technology to provide quick access to help and support.",
          ],
          Icons.info,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Features",
          [
            "• Emergency SOS with location sharing",
            "• Real-time location tracking",
            "• Community support network",
            "• Safety tips and guidelines",
            "• Multi-language support",
            "• Biometric security",
          ],
          Icons.star,
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          "Version & Updates",
          [
            "• Current Version: 1.0.0",
            "• Last Updated: August 2024",
            "• Platform: iOS & Android",
            "• Developer: SAFRA Team",
            "• Support: 24/7 Emergency Support",
          ],
          Icons.system_update,
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<String> points, IconData icon) {
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
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...points.map((point) => point.isEmpty 
            ? const SizedBox(height: 8)
            : Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  point,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }
}
