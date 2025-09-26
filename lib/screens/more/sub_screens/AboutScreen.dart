import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

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
              _buildAppBar(context, "About SAFRA"),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.local_police, size: 60, color: AppColors.primaryAccent),
                            const SizedBox(height: 8),
                            const Text("SAFRA: Safety First", style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text("Version 1.0.0", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSectionCard(
                        "Our Mission & Vision",
                        [
                          "SAFRA is dedicated to empowering women by providing immediate, discreet, and reliable emergency assistance. Our vision is a world where every individual feels secure, anytime and anywhere.",
                          "",
                          "We leverage GPS, community networking, and instant alert technology to bridge the gap between emergency and rescue.",
                        ],
                        Icons.visibility_outlined,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        "Key Features",
                        [
                          "• **Quick SOS:** One-touch alert to emergency contacts and authorities.",
                          "• **Live Location Tracking:** Continuous location sharing during high-risk travel.",
                          "• **Safety Maps:** Highlights safe zones and risky areas based on community data.",
                          "• **Safety Check-in:** Automated check-in with trusted friends/family.",
                        ],
                        Icons.star_half,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        "Meet the Founders",
                        [
                          "SAFRA was initiated as a passion project in 2024 by a cross-functional team committed to social impact through technology:",
                          "",
                          "**Project Lead:** Sara J.",
                          "**Tech Architect:** Rohan P.",
                          "**Safety & Outreach:** Dr. Anjali V.",
                          "",
                          "We are always looking to improve. Contact us with feedback!",
                        ],
                        Icons.groups_outlined,
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

  Widget _buildSectionCard(String title, List<String> points, IconData icon) {
    // Reusing the structured card for consistency
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
              Icon(icon, color: AppColors.primaryAccent, size: 24),
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
          ...points.map(
            (point) => point.isEmpty
                ? const SizedBox(height: 8)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      point,
                      style: TextStyle(
                        color: point.startsWith('•') ? AppColors.textSecondary : AppColors.textPrimary,
                        fontSize: point.startsWith('•') ? 14 : 15,
                        fontWeight: point.startsWith('**') ? FontWeight.bold : FontWeight.normal,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ],
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