import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables for toggles
  bool _locationServiceEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricLockEnabled = true;

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
              _buildAppBar(context, "App Settings"),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Security & Privacy"),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          "Location Services",
                          Icons.location_on_outlined,
                          _locationServiceEnabled,
                          (value) => setState(() => _locationServiceEnabled = value),
                        ),
                        _buildSwitchTile(
                          "Biometric Lock",
                          Icons.fingerprint_outlined,
                          _biometricLockEnabled,
                          (value) => setState(() => _biometricLockEnabled = value),
                        ),
                        _buildSettingsTile("Manage Trusted Contacts", Icons.contacts_outlined, () {
                          // TODO: Navigate to Contact Management
                        }),
                        _buildSettingsTile("Review Privacy Policy", Icons.policy_outlined, () {
                          // TODO: Open Privacy Policy link
                        }),
                      ]),
                      const SizedBox(height: 30),

                      _buildSectionTitle("Alerts & Notifications"),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          "Emergency Alerts",
                          Icons.notifications_active_outlined,
                          _emergencyAlertsEnabled,
                          (value) => setState(() => _emergencyAlertsEnabled = value),
                        ),
                        _buildSettingsTile("Safety Check-in Reminders", Icons.schedule_outlined, () {
                          // TODO: Set reminder frequency
                        }),
                        _buildSettingsTile("Customize Alert Sounds", Icons.volume_up_outlined, () {
                          // TODO: Sound customization
                        }),
                      ]),
                      const SizedBox(height: 30),

                      _buildSectionTitle("App Appearance"),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          "Dark Mode",
                          Icons.brightness_4_outlined,
                          _darkModeEnabled,
                          (value) => setState(() => _darkModeEnabled = value),
                        ),
                        _buildSettingsTile("Language (English)", Icons.language, () {
                          // TODO: Language selection
                        }),
                      ]),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Column(
        children: children.map((widget) {
          int index = children.indexOf(widget);
          return Column(
            children: [
              widget,
              // Divider for all but the last item
              if (index < children.length - 1)
                Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.glassBorder.withOpacity(0.5)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryAccent,
        inactiveThumbColor: AppColors.textSecondary,
        inactiveTrackColor: AppColors.glassBorder,
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
}