import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travelbuddy_final/utils/api_keys.dart';
import 'package:travelbuddy_final/screens/route/result_screen.dart';
import 'package:travelbuddy_final/utils/marker_generator.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();

  bool _isTrafficEnabled = false;
  MapType _currentMapType = MapType.normal;

  LatLng? _startPoint;
  LatLng? _endPoint;
  LatLng? _tempSelectedPoint;
  String _tempSelectedName = "";

  // --- SEPARATE MARKER SETS ---

  Set<Marker> _markers = {};
  // handles the warnings from Admin
  Set<Marker> _incidentMarkers = {};
  Set<Polyline> _polylines = {};


  StreamSubscription? _incidentSubscription;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.7565, 121.0583), // Batangas Default
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // --- Start listening for warnings immediately ---
    _listenToIncidents();
  }

  @override
  void dispose() {
    _searchController.clear();
    _searchController.dispose();
    _incidentSubscription?.cancel();
    super.dispose();
  }

  // --- THE WARNING LISTENER ---
  void _listenToIncidents() {
    _incidentSubscription = FirebaseFirestore.instance
        .collection('incidents')
        .where('status', isEqualTo: 'Verified')
        .snapshots()
        .listen((snapshot) async {

      Set<Marker> newIncidentMarkers = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String type = data['type'] ?? 'General Warning';
        final String desc = data['description'] ?? 'Caution advised';
        final LatLng position = LatLng(data['location_lat'], data['location_lng']);

        // 1. Determine Icon and Color based on Type
        IconData iconData = Icons.warning_amber_rounded;
        Color color = Colors.orange;

        if (type == 'Accident') {
          iconData = Icons.car_crash;
          color = Colors.red;
        } else if (type == 'Flood') {
          iconData = Icons.water_drop;
          color = Colors.blue;
        } else if (type == 'Roadwork') {
          iconData = Icons.construction;
          color = Colors.orange[800]!;
        } else if (type == 'Traffic Jam') {
          iconData = Icons.traffic;
          color = Colors.amber;
        }

        final BitmapDescriptor customIcon = await MarkerGenerator.createIconMarker(
          iconData: iconData,
          color: color,
        );

        newIncidentMarkers.add(Marker(
          markerId: MarkerId(doc.id),
          position: position,
          icon: customIcon,
          infoWindow: InfoWindow(
            title: type.toUpperCase(),
            snippet: desc,
          ),
        ));
      }

      // 4. Update the UI
      if (mounted) {
        setState(() {
          _incidentMarkers = newIncidentMarkers;
        });
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _tempSelectedPoint = pos;
      _tempSelectedName = "Selected Location";
      _updateMapObjects();
    });
  }

  Future<void> _updateMapObjects() async {
    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};

    // --- LOGIC: Navigation Pins ---
    if (_tempSelectedPoint != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId("temp_pin"),
        position: _tempSelectedPoint!,
        icon: BitmapDescriptor.defaultMarker,
      ));
    }

    if (_startPoint != null) {
      final BitmapDescriptor startIcon = await MarkerGenerator.createCapsuleMarker(
          text: "Start",
          color: Colors.blue
      );
      newMarkers.add(Marker(
        markerId: const MarkerId("start_pin"),
        position: _startPoint!,
        icon: startIcon,
        anchor: const Offset(0.5, 1.0),
      ));
    }

    if (_endPoint != null) {
      final BitmapDescriptor endIcon = await MarkerGenerator.createCapsuleMarker(
          text: "End",
          color: Colors.red
      );
      newMarkers.add(Marker(
        markerId: const MarkerId("end_pin"),
        position: _endPoint!,
        icon: endIcon,
        anchor: const Offset(0.5, 1.0),
      ));
    }

    if (_startPoint != null && _endPoint != null) {
      newPolylines.add(Polyline(
        polylineId: const PolylineId("preview_line"),
        points: [_startPoint!, _endPoint!],
        color: Colors.grey,
        width: 2,
        patterns: [PatternItem.dash(10), PatternItem.gap(10)],
      ));
    }

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });
  }

  void _setAsStart() {
    setState(() {
      _startPoint = _tempSelectedPoint;
      _tempSelectedPoint = null;
      _updateMapObjects();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Start Point Set"), duration: Duration(milliseconds: 800)),
    );
  }

  void _setAsEnd() {
    setState(() {
      _endPoint = _tempSelectedPoint;
      _tempSelectedPoint = null;
      _updateMapObjects();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Destination Set"), duration: Duration(milliseconds: 800)),
    );
  }

  void _clearAll() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _tempSelectedPoint = null;
      _updateMapObjects();
    });
  }

  void _findRoute() {
    if (_startPoint == null || _endPoint == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          startLocation: _startPoint!,
          endLocation: _endPoint!,
          trafficOption: "Normal",
        ),
      ),
    );
  }

  Future<void> _goToUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 16),
      ));
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    bool readyToRoute = (_startPoint != null && _endPoint != null);
    bool showSheet = _tempSelectedPoint != null;

    String guideText = "Tap the map to pick a location";
    IconData guideIcon = Icons.touch_app;
    Color guideColor = Colors.blueGrey;

    if (_startPoint == null && _endPoint == null) {
      guideText = "Tap anywhere to pick a Start Point";
      guideIcon = Icons.location_on_outlined;
    } else if (_startPoint != null && _endPoint == null) {
      guideText = "Now tap to pick a Destination";
      guideIcon = Icons.flag_outlined;
      guideColor = Colors.blue;
    } else if (readyToRoute) {
      guideText = "Ready to go! Tap Find Route below.";
      guideIcon = Icons.check_circle_outline;
      guideColor = Colors.green;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: _currentMapType,
            trafficEnabled: _isTrafficEnabled,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers.union(_incidentMarkers),
            polylines: _polylines,
            onMapCreated: _onMapCreated,
            onTap: _onMapTap,
            padding: EdgeInsets.only(bottom: showSheet ? 200 : 0, top: 100),
          ),

          // --- SEARCH BAR ---
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search_rounded, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GooglePlacesAutoCompleteTextFormField(
                          textEditingController: _searchController,
                          config: GoogleApiConfig(
                            apiKey: googleMapsApiKey,
                            countries: const ["ph"],
                            fetchPlaceDetailsWithCoordinates: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Search destination...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                            isDense: true,
                          ),
                          onPredictionWithCoordinatesReceived: (prediction) async {
                            if (prediction.lat != null && prediction.lng != null) {
                              final lat = double.parse(prediction.lat!);
                              final lng = double.parse(prediction.lng!);
                              final pos = LatLng(lat, lng);

                              final GoogleMapController controller = await _mapController.future;
                              controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));

                              setState(() {
                                _tempSelectedPoint = pos;
                                _tempSelectedName = prediction.description ?? "Searched Place";
                                _updateMapObjects();
                              });
                              FocusScope.of(context).unfocus();
                            }
                          },
                          onSuggestionClicked: (prediction) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                      if (_startPoint != null || _endPoint != null)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.orange),
                          tooltip: "Reset",
                          onPressed: _clearAll,
                        ),
                    ],
                  ),
                ),

                if (_tempSelectedPoint == null && !readyToRoute)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0,2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(guideIcon, size: 16, color: guideColor),
                        const SizedBox(width: 8),
                        Text(guideText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: guideColor)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // --- MAP CONTROLS ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            right: 16,
            bottom: showSheet ? 240 : (readyToRoute ? 100 : 40),
            child: Column(
              children: [
                _buildMapBtn(
                  icon: Icons.traffic_rounded,
                  isActive: _isTrafficEnabled,
                  onTap: () => setState(() => _isTrafficEnabled = !_isTrafficEnabled),
                ),
                const SizedBox(height: 12),
                _buildMapBtn(
                  icon: Icons.layers_rounded,
                  isActive: _currentMapType == MapType.hybrid,
                  onTap: () => setState(() => _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal),
                ),
                const SizedBox(height: 12),
                _buildMapBtn(
                  icon: Icons.my_location_rounded,
                  isActive: false,
                  onTap: _goToUserLocation,
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          // --- SELECTION SHEET ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            bottom: showSheet ? 0 : -220,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selected Location",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _tempSelectedName.isEmpty ? "Pinned Location" : _tempSelectedName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => setState(() => _tempSelectedPoint = null),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _setAsStart,
                          icon: const Icon(Icons.trip_origin, size: 18),
                          label: const Text("Set Start"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _setAsEnd,
                          icon: const Icon(Icons.flag, size: 18),
                          label: const Text("Set End"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- FIND ROUTE BUTTON ---
          if (readyToRoute && !showSheet)
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _findRoute,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("Find Best Route", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapBtn({required IconData icon, required bool isActive, required VoidCallback onTap, Color? color}) {
    return Material(
      color: isActive ? Colors.blue : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: isActive ? Colors.white : (color ?? Colors.black87), size: 24),
        ),
      ),
    );
  }
}