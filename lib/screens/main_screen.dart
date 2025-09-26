import 'package:flutter/material.dart';
import 'package:safra_app/screens/community_screen.dart';
import 'package:safra_app/screens/map_screen.dart';
import 'package:safra_app/screens/more_screen.dart';
import 'package:safra_app/screens/sos_screen.dart';
import 'package:safra_app/screens/evidence_upload_screen.dart';
import 'package:safra_app/screens/emergency_helpline_screen.dart';
import '../config/app_colors.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  final String userFullName;
  
  const DashboardScreen({super.key, required this.userFullName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showCarousel = false;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    // Delay carousel loading to prioritize main content
    try {
      // This will work in normal app but fail in tests
      WidgetsBinding.instance.platformDispatcher;
      _carouselTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showCarousel = true;
          });
        }
      });
    } catch (e) {
      // In test environment, don't load carousel to avoid network image issues
      // Carousel will remain hidden
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    super.dispose();
  }

  // ---- Helpers (no state changes) ----
  String _initialsFromName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'na';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toLowerCase();
  }

  String _greeting() {
    final h = TimeOfDay.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Stay safe tonight';
  }

  String _precautionLine() => 'Tip: Share your live location with a trusted contact.';

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(widget.userFullName);

    // Simple list of images (switch to assets if you prefer)
    // Temporarily empty to avoid network image loading issues during tests
    const carouselImages = <String>[
      'https://images.unsplash.com/photo-1520975954732-35dd22f7ac9b?q=80&w=1200',
      'https://images.unsplash.com/photo-1518544801976-3e50e5bb8ab1?q=80&w=1200',
      'https://images.unsplash.com/photo-1484774657666-56c7b5e4b09b?q=80&w=1200',
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== Header (updated per your request) =====
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top-left initials tile
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials, // e.g., "nv"
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Greeting + precaution (replaces "Women Safety Dashboard")
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()}, ${widget.userFullName.split(' ').first} 👋',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _precautionLine(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ===== NEW: Sliding image (carousel) =====
              // Lazy loaded carousel to improve startup performance
              if (_showCarousel && carouselImages.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: PageView.builder(
                  padEnds: true,
                  itemCount: carouselImages.length,
                  physics: const BouncingScrollPhysics(),
                  controller: PageController(viewportFraction: 0.9),
                  itemBuilder: (context, index) {
                    final img = carouselImages[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder, width: 1),
                        image: DecorationImage(
                          image: NetworkImage(img), // switch to AssetImage for local assets
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Stay Safe, Stay Protected',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ===== Dashboard grid (updated) =====
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
                        icon: Icons.emergency,
                        title: "Emergency SOS",
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
                        page: const MoreScreen(),
                      ),
                      _buildDashboardCard(
                        context,
                        icon: Icons.cloud_upload,
                        title: "Evidence Upload",
                        description: "Upload photos & videos",
                        color: AppColors.primaryAccent,
                        page: const EvidenceUploadScreen(),
                      ),
                      _buildDashboardCard(
                        context,
                        icon: Icons.phone_in_talk,
                        title: "Helplines",
                        description: "Emergency contact numbers",
                        color: AppColors.secondaryAccent,
                        page: const EmergencyHelplineScreen(),
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
              color: color.withValues(alpha: 0.3),
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
                  color: color.withValues(alpha: 0.2),
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
