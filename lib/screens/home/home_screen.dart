import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travelbuddy_final/screens/route/route_search_screen.dart';
import 'package:travelbuddy_final/screens/report/report_screen.dart';
import 'package:travelbuddy_final/widgets/weather_widget.dart';
import 'package:travelbuddy_final/widgets/traffic_widget.dart';
import 'package:travelbuddy_final/services/weather_service.dart';
import 'package:travelbuddy_final/services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- MODERN HEADER WITH DECORATION ---
            Stack(
              children: [
                // Background Gradient
                Container(
                  height: 280,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                ),
                // Decorative Circle 1
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Decorative Circle 2
                Positioned(
                  bottom: 20,
                  left: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Header Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Title (Centered)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 30.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'TravelBuddy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Welcome Text
                        Text(
                          user?.isAnonymous == true ? 'Welcome Guest' : 'Hello, ${user?.displayName?.split(' ')[0] ?? "Traveler"}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ready to explore the city today?',
                          style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- BODY CONTENT  ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. WEATHER WIDGET
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: WeatherWidget(
                          weatherService: _weatherService,
                          locationService: _locationService,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. INFORMATION BOX 1 - About TravelBuddy
                    _buildInfoCard(
                      icon: Icons.info_outline,
                      title: 'About TravelBuddy',
                      content: 'TravelBuddy is an innovative mobile application designed to simplify public transportation navigation across Batangas City. The app serves as a comprehensive travel companion that integrates real-time route information, fare estimates, weather updates, and traffic conditions into a single user-friendly platform. The proposed transportation route system integrates essential features designed to enhance user experience, security, and reliability. The system begins with a secure Author Authentication process, ensuring that only authorized users can access sensitive information and maintain the safety of their data. It also incorporates a dynamic Route Display and Tracking module, offering an interactive map that allows users to explore all available transportation routes with ease.',
                      color: const Color(0xFF1976D2),
                    ),

                    const SizedBox(height: 16),

                    // 3. INFORMATION BOX 2 - SDG Alignment
                    _buildInfoCard(
                      icon: Icons.eco_outlined,
                      title: 'Our Commitment to Climate Action',
                      content: 'This project aligns with SDG Goal No. 13: Climate Action, which focuses on reducing global greenhouse gas emissions and strengthening resilience against climate-related impacts. One major factor in rising emissions is the heavy dependence on private vehicles, which contribute significantly to air pollution, fuel consumption, and traffic congestion. By promoting the use of public transportation, the project supports a shift toward more sustainable mobility. Public transport systems can move large numbers of people using far less energy per passenger compared to individual cars, which helps lower carbon output. Encouraging commuters to choose buses, trains, and other shared transport options contributes to cleaner air, reduced traffic, and a more environmentally responsible community.',
                      color: const Color(0xFF388E3C),
                    ),

                    const SizedBox(height: 24),

                    // 4. ACTION GRID
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                      child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),

                    Row(
                      children: [
                        // Find Route Card
                        Expanded(
                          child: _buildGridActionCard(
                            context,
                            icon: Icons.map_outlined,
                            title: 'Find Route',
                            color: const Color(0xFF2196F3),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RouteSearchScreen())),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Report Card
                        Expanded(
                          child: _buildGridActionCard(
                            context,
                            icon: Icons.campaign_outlined,
                            title: 'Suggest | Report',
                            color: const Color(0xFFFF9800),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportScreen())),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 5. TRAFFIC WIDGET
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                      child: Text("Live Updates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    const TrafficWidget(),

                    const SizedBox(height: 24),

                    // 6. TIPS
                    _buildModernTipsCard(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New Info Card Widget
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  // Grid Action Card
  Widget _buildGridActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.indigo[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily Travel Tip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Traffic peaks between 7-9 AM. Consider leaving early to secure a seat on the jeepney!",
            style: TextStyle(fontSize: 14, color: Colors.indigo[800], height: 1.4),
          ),
        ],
      ),
    );
  }
}