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
      backgroundColor: const Color(0xFFF8F9FA), // Slightly cleaner white-grey
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
              offset: const Offset(0, -40), // Pulls content up to overlap header
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

                    // 2. ACTION GRID
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

                    // 3. TRAFFIC WIDGET
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                      child: Text("Live Updates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    const TrafficWidget(),

                    const SizedBox(height: 24),

                    // 4. TIPS
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

  // New Square Grid Card Design
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