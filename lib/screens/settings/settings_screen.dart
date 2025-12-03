import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travelbuddy_final/screens/auth/login_screen.dart';
import 'package:travelbuddy_final/screens/auth/register_screen.dart';
import 'package:travelbuddy_final/screens/report/report_screen.dart';
import 'package:travelbuddy_final/screens/settings/saved_routes_screen.dart'; // Ensure correct import path
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- LOGIC: EDIT NAME ---
  Future<void> _editName(String currentName) async {
    final TextEditingController nameController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(),
            hintText: "Enter your name",
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newName = nameController.text.trim();
                // Update Firebase Auth Profile
                await _currentUser!.updateDisplayName(newName);
                // Update Firestore Document
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .set({'name': newName}, SetOptions(merge: true));

                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- LOGIC: LOGOUT ---
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = _currentUser == null || _currentUser!.isAnonymous;

    // We use a StreamBuilder for the USER DATA so the name updates instantly if changed
    return StreamBuilder<DocumentSnapshot>(
        stream: isGuest
            ? null
            : FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
        builder: (context, userSnapshot) {

          // Default Data
          String displayName = _currentUser?.displayName ?? 'Traveler';
          String email = _currentUser?.email ?? '';

          // If we have Firestore data, override defaults
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? displayName;
          }

          if (isGuest) {
            displayName = "Guest Traveler";
            email = "Sign up to save routes";
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // --- HEADER (Kept as requested, but now Reactive) ---
                  _buildModernHeader(isGuest, displayName, email),

                  // --- BODY ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        _buildMenuSection(
                          title: "My Stuff",
                          children: [
                            // WRAPPING THIS TILE IN A STREAMBUILDER FOR LIVE COUNTS
                            StreamBuilder<QuerySnapshot>(
                                stream: isGuest
                                    ? null
                                    : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_currentUser!.uid)
                                    .collection('saved_routes')
                                    .snapshots(),
                                builder: (context, routeSnapshot) {
                                  int count = 0;
                                  if (routeSnapshot.hasData) {
                                    count = routeSnapshot.data!.docs.length;
                                  }

                                  return _buildMenuTile(
                                      icon: Icons.favorite_rounded,
                                      title: "Saved Routes",
                                      subtitle: isGuest ? "Sign in to access" : "$count places saved",
                                      color: Colors.pink,
                                      onTap: () {
                                        if (isGuest) {
                                          _showGuestLockDialog();
                                        } else {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedRoutesScreen()));
                                        }
                                      },
                                      isLocked: isGuest
                                  );
                                }
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _buildMenuSection(
                          title: "Preferences",
                          children: [
                            if (!isGuest)
                              _buildMenuTile(
                                  icon: Icons.lock_outline,
                                  title: "Change Password",
                                  color: Colors.orange,
                                  onTap: () {
                                    if (email.isNotEmpty) {
                                      FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset email sent! Check your inbox.")));
                                    }
                                  }
                              ),
                            _buildMenuTile(
                                icon: Icons.notifications_active_outlined,
                                title: "Notifications",
                                color: Colors.purple,
                                onTap: () {
                                  // Add notification logic later
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification settings coming soon!")));
                                }
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _buildMenuSection(
                          title: "Support",
                          children: [
                            _buildMenuTile(
                                icon: Icons.bug_report_outlined,
                                title: "Report an Issue",
                                subtitle: "Help us improve Travel Buddy",
                                color: Colors.teal,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // --- ACTIONS (Log out / Sign Up) ---
                        if (isGuest) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(color: Colors.blue.shade700),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  child: Text("Sign Up", style: TextStyle(color: Colors.blue.shade700)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  child: const Text("Log In", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          )
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _handleLogout,
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.red.withOpacity(0.08),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              child: const Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "Version 1.0.0",
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  // --- WIDGET EXTRACT: HEADER ---
  Widget _buildModernHeader(bool isGuest, String displayName, String email) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], // Your Blue Gradient
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
          ]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    isGuest ? "?" : displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (email.isNotEmpty)
                      Text(email, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
              if (!isGuest)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _editName(displayName),
                )
            ],
          ),

          if (!isGuest) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // THIS STREAMBUILDER UPDATES THE HEADER COUNT REAL-TIME
                StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUser!.uid)
                        .collection('saved_routes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "-";
                      return _buildStatItem(count, "Saved Routes");
                    }
                ),
                Container(height: 30, width: 1, color: Colors.white30), // Divider
                _buildStatItem("Registered", "Account Type"),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  void _showGuestLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Guest Mode"),
        content: const Text("Create an account to save your favorite routes and access them anytime."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe Later", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
            },
            child: const Text("Sign Up Now"),
          )
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isLocked = false
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey.shade100 : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isLocked ? Colors.grey : color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isLocked ? Colors.grey : Colors.black87)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ]
                  ],
                ),
              ),
              Icon(isLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}