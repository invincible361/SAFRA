import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../services/enhanced_language_service.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationServices = true;
  bool _emergencyAlerts = true;
  bool _safetyReminders = true;
  bool _biometricLock = false;
  bool _pinProtection = true;
  bool _dataBackup = true;
  String _selectedTheme = 'System';

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
              _buildAppBar(context, "Settings"),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Privacy & Security"),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          "Location Services",
                          "Allow app to access your location",
                          Icons.location_on,
                          _locationServices,
                          (value) => setState(() => _locationServices = value),
                        ),
                        _buildSwitchTile(
                          AppLocalizations.of(context)?.biometricLock ?? 'Biometric Lock',
                          AppLocalizations.of(context)?.biometricLockDesc ?? 'Use Face ID/Touch ID for app access',
                          Icons.fingerprint,
                          _biometricLock,
                          (value) => setState(() => _biometricLock = value),
                        ),
                        _buildSwitchTile(
                          AppLocalizations.of(context)?.pinProtection ?? 'PIN Protection',
                          AppLocalizations.of(context)?.pinProtectionDesc ?? 'Set a PIN code for additional security',
                          Icons.lock,
                          _pinProtection,
                          (value) => setState(() => _pinProtection = value),
                        ),
                        _buildSwitchTile(
                          AppLocalizations.of(context)?.dataBackup ?? 'Data Backup',
                          AppLocalizations.of(context)?.dataBackupDesc ?? 'Automatically backup your data',
                          Icons.backup,
                          _dataBackup,
                          (value) => setState(() => _dataBackup = value),
                        ),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle(AppLocalizations.of(context)?.notifications ?? 'Notifications'),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          AppLocalizations.of(context)?.emergencyAlerts ?? 'Emergency Alerts',
                          AppLocalizations.of(context)?.emergencyAlertsDesc ?? 'Receive immediate emergency notifications',
                          Icons.emergency,
                          _emergencyAlerts,
                          (value) => setState(() => _emergencyAlerts = value),
                        ),
                        _buildSwitchTile(
                          AppLocalizations.of(context)?.safetyReminders ?? 'Safety Reminders',
                          AppLocalizations.of(context)?.safetyRemindersDesc ?? 'Get periodic safety tips and reminders',
                          Icons.notifications,
                          _safetyReminders,
                          (value) => setState(() => _safetyReminders = value),
                        ),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle(AppLocalizations.of(context)?.appPreferences ?? 'App Preferences'),
                      Consumer<EnhancedLanguageService>(
                        builder: (context, languageService, child) {
                          final currentLanguage = languageService.getLanguageName(languageService.getCurrentLanguageCode());
                          return _buildSettingsCard([
                            _buildDropdownTile(
                              AppLocalizations.of(context)?.language ?? 'Language',
                              AppLocalizations.of(context)?.languageDesc ?? 'Choose your preferred language',
                              Icons.language,
                              currentLanguage,
                              ['English', 'Hindi', 'Kannada'],
                              (value) {
                                if (value != null) {
                                  // Map display names to language codes
                                  final languageCode = {
                                    'English': 'en',
                                    'Hindi': 'hi',
                                    'Kannada': 'kn',
                                  }[value];
                                  if (languageCode != null) {
                                    languageService.setLanguage(languageCode);
                                  }
                                }
                              },
                            ),
                        _buildDropdownTile(
                          AppLocalizations.of(context)?.theme ?? 'Theme',
                          AppLocalizations.of(context)?.themeDesc ?? 'Select app theme',
                          Icons.palette,
                          _selectedTheme,
                          ['System', 'Light', 'Dark'],
                          (value) => setState(() => _selectedTheme = value!),
                        ),
                      ]);
                    },
                  ),
                      
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle(AppLocalizations.of(context)?.dataStorage ?? 'Data & Storage'),
                      _buildSettingsCard([
                        _buildActionTile(
                          AppLocalizations.of(context)?.clearCache ?? 'Clear Cache',
                          AppLocalizations.of(context)?.clearCacheDesc ?? 'Clear temporary app data',
                          Icons.clear_all,
                          () {
                            // TODO: Implement clear cache
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)?.cacheCleared ?? 'Cache cleared successfully!')),
                            );
                          },
                        ),
                        _buildActionTile(
                          AppLocalizations.of(context)?.exportData ?? 'Export Data',
                          AppLocalizations.of(context)?.exportDataDesc ?? 'Download your app data',
                          Icons.download,
                          () {
                            // TODO: Implement export data
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)?.exportDataComingSoon ?? 'Data export feature coming soon!')),
                            );
                          },
                        ),
                        _buildActionTile(
                          AppLocalizations.of(context)?.deleteAccount ?? 'Delete Account',
                          AppLocalizations.of(context)?.deleteAccountDesc ?? 'Permanently delete your account',
                          Icons.delete_forever,
                          () {
                            _showDeleteAccountDialog(context);
                          },
                          color: Colors.red,
                        ),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle(AppLocalizations.of(context)?.about ?? 'About'),
                      _buildSettingsCard([
                        _buildInfoTile(AppLocalizations.of(context)?.appVersion ?? 'App Version', "1.0.0"),
                        _buildInfoTile(AppLocalizations.of(context)?.buildNumber ?? 'Build Number', "100"),
                        _buildInfoTile(AppLocalizations.of(context)?.lastUpdated ?? 'Last Updated', "August 2024"),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
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
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryAccent, // TODO: Update to activeThumbColor when Flutter 3.31+ is used
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, IconData icon, String value, List<String> options, Function(String?) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.darkBackground, // Changed to opaque background
        style: const TextStyle(color: AppColors.textPrimary),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primaryAccent, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: AppColors.primaryAccent, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.glassBackground,
          title: Text(AppLocalizations.of(context)?.deleteAccount ?? "Delete Account", style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(
            AppLocalizations.of(context)?.deleteAccountConfirm ?? "Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)?.cancel ?? "Cancel", style: const TextStyle(color: AppColors.textPrimary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement account deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)?.deleteAccountComingSoon ?? "Account deletion feature coming soon!")),
                );
              },
              child: Text(AppLocalizations.of(context)?.delete ?? "Delete", style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}