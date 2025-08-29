import 'package:flutter/material.dart';
import 'package:safra_app/screens/community_screen.dart';
import 'package:safra_app/screens/contact_selection_screen.dart';
import 'package:safra_app/screens/map_screen.dart';
import 'package:safra_app/screens/more_screen.dart';
import 'package:safra_app/screens/sos_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark theme background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Women Safety Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
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
              color: Colors.red,
              page: EmergencySOSScreen(),
            ),
            
            _buildDashboardCard(
              context,
              icon: Icons.map,
              title: "Safe Routes",
              description: "Navigate safe travel paths",
              color: Colors.green,
              page: const MapScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.group,
              title: "Community",
              description: "Connect with helpers nearby",
              color: Colors.orange,
              page: const CommunityScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.more_horiz,
              title: "More",
              description: "Explore more options",
              color: Colors.grey,
              page: const MoreScreen()
            ),
          ],
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
      child: Card(
        color: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
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
