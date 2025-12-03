import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travelbuddy_final/utils/marker_generator.dart';

class IncidentViewScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final String type;
  final String description;

  const IncidentViewScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.type,
    required this.description,
  });

  @override
  State<IncidentViewScreen> createState() => _IncidentViewScreenState();
}

class _IncidentViewScreenState extends State<IncidentViewScreen> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  // --- 1. ASYNC MARKER LOADER ---
  Future<void> _loadCustomMarker() async {
    final IconData iconData = _getIcon();
    final Color color = _getColor();
    final LatLng position = LatLng(widget.lat, widget.lng);

    try {
      final BitmapDescriptor customIcon = await MarkerGenerator.createIconMarker(
        iconData: iconData,
        color: color,
      );

      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('incident'),
            position: position,
            icon: customIcon,
            infoWindow: InfoWindow(title: widget.type, snippet: "Caution Advised"),
          ),
        };
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        _controller.showMarkerInfoWindow(const MarkerId('incident'));
      });

    } catch (e) {
      print("Error loading custom marker: $e");
    }
  }

  // --- HELPER: Get Color ---
  Color _getColor() {
    switch (widget.type) {
      case 'Flood': return Colors.blue;
      case 'Roadwork': return Colors.orange[800]!;
      case 'Accident': return Colors.red;
      case 'Traffic Jam': return Colors.amber[800]!;
      case 'Route Error': return Colors.purple;
      default: return Colors.amber;
    }
  }

  // --- HELPER: Get Icon Data ---
  IconData _getIcon() {
    switch (widget.type) {
      case 'Flood': return Icons.water_drop;
      case 'Roadwork': return Icons.construction;
      case 'Accident': return Icons.car_crash;
      case 'Traffic Jam': return Icons.traffic;
      case 'Route Error': return Icons.wrong_location;
      default: return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng position = LatLng(widget.lat, widget.lng);
    final Color themeColor = _getColor();
    final IconData themeIcon = _getIcon();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
            widget.type.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)
        ),
        backgroundColor: themeColor,
        centerTitle: true,
        elevation: 4,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black12,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: position, zoom: 17, tilt: 40),
            padding: const EdgeInsets.only(bottom: 250),
            markers: _markers, // 👈 Use the loaded markers
            onMapCreated: (c) => _controller = c,
            zoomControlsEnabled: false, // Clean look
          ),

          // --- DETAIL CARD ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(themeIcon, color: themeColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CAUTION ADVISED",
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.type,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "INCIDENT REPORT:",
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Dismiss Alert", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}