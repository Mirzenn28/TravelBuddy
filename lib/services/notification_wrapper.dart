import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travelbuddy_final/screens/route/incident_view_screen.dart';

class NotificationWrapper extends StatefulWidget {
  final Widget child;

  const NotificationWrapper({super.key, required this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _setupInteractedMessage();
  }

  // 1. BACKGROUND CLICKS
  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // 2. NAVIGATION LOGIC
  void _handleMessage(RemoteMessage message) {
    if (message.data['lat'] != null && message.data['lng'] != null) {
      try {
        double lat = double.parse(message.data['lat'].toString());
        double lng = double.parse(message.data['lng'].toString());
        String type = message.data['incident_type'] ?? "Alert";
        String desc = message.notification?.body ?? "Incident reported";

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncidentViewScreen(
              lat: lat, lng: lng, type: type, description: desc,
            ),
          ),
        );
      } catch (e) {
        print("Error parsing notification: $e");
      }
    }
  }

  // 3. FOREGROUND LISTENER
  Future<void> _setupNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcm_token': token,
          'last_token_update': FieldValue.serverTimestamp(),
        });
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null && mounted) {
          // GLOBAL SNACKBAR
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
                        Text(message.notification!.title ?? "Alert", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(message.notification!.body ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: "VIEW",
                textColor: Colors.yellowAccent,
                onPressed: () {
                  _handleMessage(message);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}