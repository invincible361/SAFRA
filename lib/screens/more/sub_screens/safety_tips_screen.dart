import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({Key? key}) : super(key: key);

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
              _buildAppBar(context, "Safety Tips"),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        "Home Safety",
                        [
                          "• Always lock doors and windows",
                          "• Don't open the door to strangers",
                          "• Install proper lighting around your home",
                          "• Keep emergency numbers visible",
                          "• Have a safety plan for emergencies",
                        ],
                        Icons.home,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        "Workplace Safety",
                        [
                          "• Know your company's safety policies",
                          "• Keep personal items secure",
                          "• Trust your instincts about uncomfortable situations",
                          "• Report any harassment or unsafe conditions",
                          "• Have emergency contacts readily available",
                        ],
                        Icons.work,
                      ),
                      const SizedBox(height: 20),
                      _buildEmergencyContactsCard(),
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

  Widget _buildEmergencyContactsCard() {
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
              const Icon(
                Icons.phone,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Emergency Contacts",
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
          _buildEmergencyContactRow("Police", "100", Colors.red),
          _buildEmergencyContactRow("Fire Brigade", "101", Colors.orange),
          _buildEmergencyContactRow("Ambulance", "108", Colors.blue),
          _buildEmergencyContactRow("Women Helpline", "1091", Colors.purple),
          _buildEmergencyContactRow("Child Helpline", "1098", Colors.green),
          _buildEmergencyContactRow("Senior Citizen Helpline", "14567", Colors.teal),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactRow(String service, String number, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                number,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.phone,
                color: color,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}