import 'package:flutter/material.dart';
import 'package:safra_app/screens/community_screen.dart';
import 'package:safra_app/screens/contact_selection_screen.dart';
import 'package:safra_app/screens/map_screen.dart';
import 'package:safra_app/screens/more_screen.dart';
import 'package:safra_app/screens/sos_screen.dart';
import '../config/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                    const Icon(
                      Icons.shield,
                      color: AppColors.textPrimary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Women Safety Dashboard",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dashboard Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardCard(
                        context,
                        icon: Icons.sos,
                        title: "SOS",
                        description: "Send instant help alert",
                        color: AppColors.error,
                        page: const EmergencySOSScreen(),
                      ),
                      
                      _buildDashboardCard(
                        context,
                        icon: Icons.map,
                        title: "Safe Routes",
                        description: "Navigate safe travel paths",
                        color: AppColors.success,
                        page: const MapScreen(),
                      ),
                      _buildDashboardCard(
                        context,
                        icon: Icons.group,
                        title: "Community",
                        description: "Connect with helpers nearby",
                        color: AppColors.warning,
                        page: const CommunityScreen(),
                      ),
                      _buildDashboardCard(
                        context,
                        icon: Icons.more_horiz,
                        title: "More",
                        description: "Explore more options",
                        color: AppColors.info,
                        page: const MoreScreen()
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

  // 🔹 Card widget reused for each box
  Widget _buildDashboardCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required Color color,
        required Widget page,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
