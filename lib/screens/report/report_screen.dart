import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // --- CONTROLLERS ---
  final _descriptionController = TextEditingController();
  final _stopNameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();

  // --- STATE ---
  String _selectedType = 'Accident';
  final List<String> _reportTypes = [
    'Accident',
    'Traffic Jam',
    'Roadwork',
    'Flood',
    'Route Error',
    'Stop Suggestion'
  ];

  // --- LOCATION DATA  ---
  LatLng? _centerPin;
  LatLng? _startPin;
  LatLng? _endPin;
  Set<Marker> _markers = {};

  bool _isSubmitting = false;
  bool _isRouteErrorMode = false;

  // Default location
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.7565, 121.0583),
    zoom: 15,
  );

  // --- THEME COLORS (VISUALS ONLY) ---
  final Color _brandBlue = const Color(0xFF2563EB); // TravelBuddy Blue
  final Color _bgLight = const Color(0xFFF8FAFC);   // Slate 50

  @override
  void initState() {
    super.initState();
    _goToUserLocation();
  }

  // 1. Get User Location
  Future<void> _goToUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 16),
      ));
      setState(() {
        _centerPin = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Handle permission errors
    }
  }

  // 2. Handle Map Movement
  void _onMapCameraMove(CameraPosition position) {
    if (!_isRouteErrorMode) {
      setState(() {
        _centerPin = position.target;
      });
    }
  }

  // 3. Update Markers
  void _updateMarkers() {
    Set<Marker> newMarkers = {};

    if (_isRouteErrorMode) {
      if (_startPin != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('start'),
          position: _startPin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: "Start of Error"),
        ));
      }
      if (_endPin != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('end'),
          position: _endPin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "End of Error"),
        ));
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  // 4. Handle Dropdown Change (
  void _handleTypeChange(String? newValue) {
    setState(() {
      _selectedType = newValue!;
      _isRouteErrorMode = (_selectedType == 'Route Error');
      _startPin = null;
      _endPin = null;
      _markers.clear();
    });
  }

  // 5. Submit to Firebase (
  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a description")));
      return;
    }

    if (_isRouteErrorMode) {
      if (_startPin == null || _endPin == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please tap map to mark Start AND End points")));
        return;
      }
    } else {
      if (_centerPin == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please move map to pinpoint location")));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> data = {
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'status': 'Pending',
        'user_id': user?.uid ?? 'guest',
        'is_guest': user?.isAnonymous ?? true,
        'reported_at': FieldValue.serverTimestamp(),
        'location_lat': _isRouteErrorMode ? _startPin!.latitude : _centerPin!.latitude,
        'location_lng': _isRouteErrorMode ? _startPin!.longitude : _centerPin!.longitude,
      };

      if (_isRouteErrorMode) {
        data['end_lat'] = _endPin!.latitude;
        data['end_lng'] = _endPin!.longitude;
      }

      if (_selectedType == 'Stop Suggestion') {
        data['stop_name'] = _stopNameController.text.trim();
        data['contact_info'] = _contactInfoController.text.trim();
      }

      await FirebaseFirestore.instance.collection('incidents').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Report Submitted! An admin will review it shortly."),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- HELPER: UI BUILDER FOR TEXT FIELDS ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _brandBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    bool isStopSuggestion = _selectedType == 'Stop Suggestion';
    Color activeColor = isStopSuggestion ? Colors.green : _brandBlue;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Report Issue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. MODERN MAP HEADER ---
            SizedBox(
              height: 380,
              child: Stack(
                children: [
                  // The Map with Rounded Bottom
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    child: GoogleMap(
                      initialCameraPosition: _initialPosition,
                      onMapCreated: (c) => _mapController.complete(c),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      onCameraMove: _onMapCameraMove,
                      onTap: _isRouteErrorMode ? (pos) {
                        if (_startPin == null) {
                          setState(() => _startPin = pos);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Start set. Now tap End point.")));
                        } else if (_endPin == null) {
                          setState(() => _endPin = pos);
                        } else {
                          setState(() { _startPin = pos; _endPin = null; });
                        }
                        _updateMarkers();
                      } : null,
                    ),
                  ),

                  // Stationary Pin (Visual Only)
                  if (!_isRouteErrorMode)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 42),
                        child: Icon(
                          Icons.location_on, // <--- CHANGED: Always uses the Pinpoint icon
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                    ),

                  // Floating Instruction Banner
                  Positioned(
                    top: 20, left: 30, right: 30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isRouteErrorMode ? Icons.touch_app : Icons.open_with, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _isRouteErrorMode ? "Tap map for Start & End" : "Drag map to pinpoint",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Locate Me Button
                  Positioned(
                    bottom: 30, right: 20,
                    child: FloatingActionButton(
                      onPressed: _goToUserLocation,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.my_location, color: _brandBlue),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. FORM SECTION ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Incident Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                  const SizedBox(height: 16),

                  // Custom Dropdown Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey[100]!),
                      boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: _brandBlue),
                        items: _reportTypes.map((t) => DropdownMenuItem(
                            value: t,
                            child: Row(children: [
                              Icon(t == 'Stop Suggestion' ? Icons.add_location_alt : Icons.report_problem,
                                  size: 18,
                                  color: t == 'Stop Suggestion' ? Colors.green : (t == 'Accident' ? Colors.red : Colors.orange)
                              ),
                              const SizedBox(width: 12),
                              Text(t)
                            ])
                        )).toList(),
                        onChanged: _handleTypeChange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dynamic Fields
                  if (isStopSuggestion) ...[
                    _buildTextField(
                      controller: _stopNameController,
                      label: "Proposed Stop Name",
                      icon: Icons.signpost,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _contactInfoController,
                      label: "Contact Info (Optional)",
                      icon: Icons.contact_mail,
                    ),
                    const SizedBox(height: 20),
                  ],

                  _buildTextField(
                    controller: _descriptionController,
                    label: "Description",
                    icon: Icons.description,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitReport,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      label: Text(_isSubmitting ? "Sending..." : "Submit Report"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}