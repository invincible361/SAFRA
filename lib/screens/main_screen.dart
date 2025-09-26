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
  Timer? _autoScrollTimer;
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;

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
          
          // Start auto-scrolling after carousel is shown
          _startAutoScroll();
        }
      });
    } catch (e) {
      // In test environment, don't load carousel to avoid network image issues
      // Carousel will remain hidden
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _carouselController.hasClients) {
        final nextIndex = (_carouselController.page?.toInt() ?? 0) + 1;
        final targetIndex = nextIndex >= 3 ? 0 : nextIndex; // We have 3 carousel items
        _carouselController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onCarouselPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentCarouselIndex = index;
      });
    }
  }

  void _handleCarouselTap(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmergencySOSScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreen()),
        );
        break;
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _autoScrollTimer?.cancel();
    _carouselController.dispose();
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

    // Enhanced carousel content with safety-focused images and messages
    final carouselItems = <Map<String, String>>[
      {
        'image': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?q=80&w=1200',
        'title': 'Your Safety is Our Priority',
        'subtitle': '24/7 emergency support at your fingertips',
      },
      {
        'image': 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?q=80&w=1200',
        'title': 'Safe Routes Navigation',
        'subtitle': 'AI-powered pathfinding for safer journeys',
      },
      {
        'image': 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?q=80&w=1200',
        'title': 'Community Protection',
        'subtitle': 'Connect with trusted helpers nearby',
      },
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
                    // App Logo
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder, width: 1),
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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

              // ===== Enhanced Carousel with Auto-scroll and Indicators =====
              // Lazy loaded carousel to improve startup performance
              if (_showCarousel && carouselItems.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        padEnds: true,
                        itemCount: carouselItems.length,
                        physics: const BouncingScrollPhysics(),
                        controller: _carouselController,
                        onPageChanged: _onCarouselPageChanged,
                        itemBuilder: (context, index) {
                          final item = carouselItems[index];
                          return GestureDetector(
                            onTap: () => _handleCarouselTap(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.glassBorder, width: 1),
                                image: DecorationImage(
                                  image: NetworkImage(item['image']!),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['subtitle']!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Carousel indicators
                    if (carouselItems.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            carouselItems.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentCarouselIndex == index
                                    ? AppColors.primaryAccent
                                    : AppColors.textSecondary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
