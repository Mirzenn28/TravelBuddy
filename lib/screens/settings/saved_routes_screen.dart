import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travelbuddy_final/screens/route/route_details_screen.dart';
import 'package:travelbuddy_final/screens/route/incident_view_screen.dart'; // Ensure this import is correct
import 'package:firebase_messaging/firebase_messaging.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _setupInteractedMessage(); // Handles clicks when app is closed/background
  }

  // --- 1. HANDLE CLICKS (Background & Terminated) ---
  Future<void> _setupInteractedMessage() async {
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // --- 2. NAVIGATION LOGIC (With Safety Fix) ---
  void _handleMessage(RemoteMessage message) {
    // Check if data exists
    if (message.data['lat'] != null && message.data['lng'] != null) {
      try {
        // Safely parse string/number to double
        double lat = double.parse(message.data['lat'].toString());
        double lng = double.parse(message.data['lng'].toString());

        String type = message.data['incident_type'] ?? "Alert";
        String desc = message.notification?.body ?? "Incident reported";

        // Navigate to the Incident View
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncidentViewScreen(
              lat: lat,
              lng: lng,
              type: type,
              description: desc,
            ),
          ),
        );
      } catch (e) {
        print("Error parsing notification coordinates: $e");
      }
    }
  }

  // --- 3. SETUP & FOREGROUND LISTENER ---
  Future<void> _setupNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request Permission (Required for iOS/Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Save Token to Firestore
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcm_token': token,
          'last_token_update': FieldValue.serverTimestamp(),
        });
      }

      // LISTEN FOR NOTIFICATIONS WHILE APP IS OPEN (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📨 SPY: Flutter actually got the message! Title: ${message.notification?.title}");
        if (message.notification != null && mounted) {
          // Show Red Banner
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red[800],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 10),
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.notification!.title ?? "Travel Alert",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.notification!.body ?? "Incident reported on your route.",
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Button to Open Map
              action: SnackBarAction(
                label: "VIEW",
                textColor: Colors.yellowAccent,
                onPressed: () {
                  _handleMessage(message); // Reuse the navigation logic
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      });
    }
  }

  // --- 4. UI BUILD ---
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "My Saved Trips",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('saved_routes')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading routes"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No saved routes yet",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Search for a route and tap ❤️ to save it.",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red[700], size: 30),
                ),
                onDismissed: (direction) {
                  doc.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Route removed")),
                  );
                },
                child: _buildRouteCard(context, data),
              );
            },
          );
        },
      ),
    );
  }

  // --- 5. HELPER WIDGETS ---
  Widget _buildRouteCard(BuildContext context, Map<String, dynamic> data) {
    final startName = data['start_name'] ?? "Unknown Origin";
    final endName = data['end_name'] ?? "Unknown Dest";
    final totalFare = data['total_fare'] ?? "₱0";
    final totalTime = data['total_time'] ?? "0 min";

    // Extract Legs safely for icons
    List<dynamic> legs = [];
    if (data['route_data'] != null && data['route_data']['legs'] != null) {
      legs = data['route_data']['legs'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (data['route_data'] != null && data['end_lat'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(
                    routeData: data['route_data'],
                    finalDestination: LatLng(data['end_lat'], data['end_lng']),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Outdated route data. Please delete.")),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Timeline Section (A -> B)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Graphics
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 12, color: Colors.green),
                        Container(
                          height: 30,
                          width: 2,
                          color: Colors.grey[200],
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        const Icon(Icons.location_on, size: 16, color: Colors.red),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            startName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 24), // Spacer for the line
                          Text(
                            endName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Stats & Mode Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stats
                    Row(
                      children: [
                        _buildBadge(Icons.access_time_filled, totalTime, Colors.blue),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.account_balance_wallet, totalFare, Colors.green),
                      ],
                    ),

                    // Transport Mode Icons (Visual Summary)
                    if (legs.isNotEmpty)
                      Row(
                        children: [
                          // Show max 3 icons to prevent overflow
                          ...legs.take(3).map((leg) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _getTransportIcon(leg),
                            );
                          }),
                          if (legs.length > 3)
                            Text(" +${legs.length - 3}", style: const TextStyle(fontSize: 10, color: Colors.grey))
                        ],
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTransportIcon(dynamic leg) {
    final type = (leg['route_type'] ?? '').toString().toUpperCase();
    IconData icon;
    Color color;

    if (type == 'WALK') {
      icon = Icons.directions_walk;
      color = Colors.grey;
    } else if (type.contains('TRICYCLE')) {
      icon = Icons.electric_rickshaw; // Or similar
      color = Colors.orange;
    } else if (type.contains('JEEP')) {
      icon = Icons.directions_bus_filled; // Placeholder for Jeep
      color = Colors.blue;
    } else {
      icon = Icons.directions_bus;
      color = Colors.blue;
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, size: 14, color: color),
    );
  }
}