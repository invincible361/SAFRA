import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'more/sub_screens/profile_screen.dart';
import 'more/sub_screens/help_screen.dart';
import 'more/sub_screens/safety_tips_screen.dart';
import 'more/sub_screens/settings_screen.dart';
import 'more/sub_screens/about_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> moreOptions = const [
    {"icon": Icons.account_circle_outlined, "title": "Profile", "screen": ProfileScreen()},
    {"icon": Icons.help_outline, "title": "Help", "screen": HelpScreen()},
    {"icon": Icons.safety_check_outlined, "title": "Safety Tips", "screen": SafetyTipsScreen()},
    {"icon": Icons.settings, "title": "Settings", "screen": SettingsScreen()},
    {"icon": Icons.info_outline, "title": "About", "screen": AboutScreen()},
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
              _buildAppBar(context, "More Options"),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: moreOptions.length,
                  itemBuilder: (context, index) {
                    final item = moreOptions[index];
                    return _buildOptionTile(
                      context,
                      item["icon"] as IconData,
                      item["title"] as String,
                      item["screen"] as Widget,
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

  Widget _buildOptionTile(BuildContext context, IconData icon, String title, Widget screen) {
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
          icon,
          color: AppColors.primaryAccent,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }
}
