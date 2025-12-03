import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travelbuddy_final/utils/app_colors.dart';
import 'package:travelbuddy_final/utils/marker_generator.dart';
import 'package:travelbuddy_final/widgets/fare_breakdown_sheet.dart';
import 'package:travelbuddy_final/widgets/weather_forecast_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailScreen extends StatefulWidget {
  final dynamic routeData;
  final LatLng finalDestination;

  const DetailScreen({
    super.key,
    required this.routeData,
    required this.finalDestination,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  final Set<Polyline> _polylines = {};

  // Layer 1: Route Markers (Start, End, Transfers)
  final Set<Marker> _markers = {};

  // Layer 2: Incident Markers (Accidents, Floods, etc.)
  Set<Marker> _incidentMarkers = {};
  StreamSubscription? _incidentSubscription;

  LatLngBounds? _routeBounds;
  bool _isMapDataLoading = true;

  @override
  void initState() {
    super.initState();
    _buildRouteMapData();
    // --- Start listening for warnings immediately ---
    _listenToIncidents();
  }

  @override
  void dispose() {
    // --- Cancel listener to stop memory leaks ---
    _incidentSubscription?.cancel();
    super.dispose();
  }

  // --- INCIDENT LISTENER (Same logic as ExploreScreen) ---
  void _listenToIncidents() {
    _incidentSubscription = FirebaseFirestore.instance
        .collection('incidents')
        .where('status', isEqualTo: 'Verified')
        .snapshots()
        .listen((snapshot) async {

      Set<Marker> newIncidentMarkers = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Safety Check for Coordinates
          double lat = (data['location_lat'] is num) ? (data['location_lat'] as num).toDouble() : 0.0;
          double lng = (data['location_lng'] is num) ? (data['location_lng'] as num).toDouble() : 0.0;

          if (lat == 0.0 || lng == 0.0) continue;

          final String type = data['type'] ?? 'General Warning';
          final String desc = data['description'] ?? 'Caution advised';

          // Icon Mapping
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
            position: LatLng(lat, lng),
            icon: customIcon,
            infoWindow: InfoWindow(
              title: type.toUpperCase(),
              snippet: desc,
            ),
          ));

        } catch (e) {
          print("Error processing incident marker: $e");
        }
      }

      if (mounted) {
        setState(() {
          _incidentMarkers = newIncidentMarkers;
        });
      }
    });
  }

  /// Helper function to create LatLngBounds from a list of points
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;

    for (final latLng in list) {
      if (minLat == null || latLng.latitude < minLat) {
        minLat = latLng.latitude;
      }
      if (maxLat == null || latLng.latitude > maxLat) {
        maxLat = latLng.latitude;
      }
      if (minLng == null || latLng.longitude < minLng) {
        minLng = latLng.longitude;
      }
      if (maxLng == null || latLng.longitude > maxLng) {
        maxLng = latLng.longitude;
      }
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  /// Decodes polylines, creates markers, and calculates map bounds
  Future<void> _buildRouteMapData() async {
    try {
      final List<dynamic> legs = widget.routeData['legs'];

      _polylines.clear();
      _markers.clear();
      List<LatLng> allPoints = [];

      // --- 1. MARKERS: START & END ---
      final BitmapDescriptor startIcon = await MarkerGenerator.createCapsuleMarker(
          text: "Start",
          color: Colors.blue
      );

      final BitmapDescriptor endIcon = await MarkerGenerator.createCapsuleMarker(
          text: "End",
          color: Colors.red
      );

      // Add End Marker
      allPoints.add(widget.finalDestination);
      _markers.add(Marker(
        markerId: const MarkerId('DEST'),
        position: widget.finalDestination,
        icon: endIcon,
        anchor: const Offset(0.5, 1.0),
      ));

      // Add Start Marker
      final startLocationCoords = Map<String, dynamic>.from(widget.routeData['start_location_coords'] as Map);
      final startUserLatLng = LatLng(startLocationCoords['_latitude'], startLocationCoords['_longitude']);
      allPoints.add(startUserLatLng);
      _markers.add(Marker(
        markerId: const MarkerId('START'),
        position: startUserLatLng,
        icon: startIcon,
        anchor: const Offset(0.5, 1.0),
      ));

      // --- 2. LOOP THROUGH LEGS ---
      for (int i = 0; i < legs.length; i++) {
        final leg = Map<String, dynamic>.from(legs[i] as Map);
        final String polylineString = leg['polyline'] ?? "";
        final String type = (leg['route_type'] ?? 'WALK').toString().toUpperCase();

        final startCoordsMap = Map<String, dynamic>.from(leg['start_stop_coords'] as Map);
        final endCoordsMap = Map<String, dynamic>.from(leg['end_stop_coords'] as Map);
        final legStartPos = LatLng(startCoordsMap['_latitude'], startCoordsMap['_longitude']);
        final legEndPos = LatLng(endCoordsMap['_latitude'], endCoordsMap['_longitude']);

        Color legColor = AppColors.getColorByType(type);
        List<PatternItem> legPattern = [];

        if (type.contains('WALK')) {
          legColor = Colors.grey;
          legPattern = [PatternItem.dot, PatternItem.gap(10)];
        } else if (type.contains('TRICYCLE')) {
          legColor = AppColors.tricycle;
          legPattern = [PatternItem.dash(20), PatternItem.gap(10)];
        }

        List<LatLng> points = [];
        if (polylineString.isNotEmpty) {
          try {
            points = _decodePolyline(polylineString);
          } catch (e) {
            print("Error decoding polyline: $e");
          }
        }
        if (points.isEmpty) {
          points = [legStartPos, legEndPos];
        }

        if (points.isNotEmpty) {
          _polylines.add(Polyline(
            polylineId: PolylineId('leg_$i'),
            color: legColor,
            width: 5,
            points: points,
            patterns: legPattern,
          ));
          allPoints.addAll(points);
        }

        if (i < legs.length - 1) {
          final endCoordsMap = Map<String, dynamic>.from(leg['end_stop_coords'] as Map);
          final transferPos = LatLng(endCoordsMap['_latitude'], endCoordsMap['_longitude']);

          final nextLeg = Map<String, dynamic>.from(legs[i+1] as Map);
          final nextLegType = (nextLeg['route_type'] ?? 'WALK').toString();
          final Color nextColor = AppColors.getColorByType(nextLegType);
          final IconData nextIconData = AppColors.getIconByType(nextLegType);

          final BitmapDescriptor transferIcon = await MarkerGenerator.createIconMarker(
              iconData: nextIconData,
              color: nextColor
          );

          _markers.add(Marker(
            markerId: MarkerId('transfer_$i'),
            position: transferPos,
            icon: transferIcon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(title: "Transfer to $nextLegType"),
          ));
          allPoints.add(transferPos);
        }
      }

      if (allPoints.isNotEmpty) {
        _routeBounds = _boundsFromLatLngList(allPoints);
      }

    } catch (e) {
      print("CRITICAL ERROR building map data: $e");
    }

    if (mounted) {
      setState(() {
        _isMapDataLoading = false;
      });
    }
    _zoomToRoute();
  }

  Future<void> _zoomToRoute() async {
    if (_routeBounds == null) return;
    final GoogleMapController controller = await _mapController.future;
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      controller.animateCamera(CameraUpdate.newLatLngBounds(_routeBounds!, 50.0));
    }
  }

  double _getFinalDistance() {
    final lastLeg = Map<String, dynamic>.from(widget.routeData['legs'].last as Map);
    final lastStopCoords = Map<String, dynamic>.from(lastLeg['end_stop_coords'] as Map);
    return Geolocator.distanceBetween(
      lastStopCoords['_latitude'],
      lastStopCoords['_longitude'],
      widget.finalDestination.latitude,
      widget.finalDestination.longitude,
    );
  }

  // --- SAVE ROUTE FUNCTION ---
  Future<void> _saveRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please create an account to save routes.")),
      );
      return;
    }

    final startCoord = Map<String, dynamic>.from(widget.routeData['start_location_coords'] as Map);

    // Logic to get clean names
    String startName = "Start Location";
    String endName = "Destination";
    final List<dynamic> legs = widget.routeData['legs'];

    if (legs.isNotEmpty) {
      final firstLeg = Map<String, dynamic>.from(legs.first as Map);
      final lastLeg = Map<String, dynamic>.from(legs.last as Map);
      startName = firstLeg['start_stop_name'] ?? "Start Location";
      if (startName == "Your Starting Point") startName = "My Location";
      endName = lastLeg['end_stop_name'] ?? "Destination";
      if (endName == "Your Destination") endName = "Selected Destination";
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_routes')
          .add({
        // Metadata for the List View
        'start_name': startName,
        'end_name': endName,
        'start_lat': startCoord['_latitude'],
        'start_lng': startCoord['_longitude'],
        'end_lat': widget.finalDestination.latitude,
        'end_lng': widget.finalDestination.longitude,
        'created_at': FieldValue.serverTimestamp(),
        'total_fare': widget.routeData['total_fare_formatted'],
        'total_time': widget.routeData['total_time_formatted'],
        'route_data': widget.routeData,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Route saved to favorites! ❤️")),
        );
      }
    } catch (e) {
      print("Error saving route: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> legs = widget.routeData['legs'];
    final weatherRaw = widget.routeData['weather_destination'];

    final List<dynamic>? destWeather = (weatherRaw is List && weatherRaw.isNotEmpty) ? weatherRaw : null;
    final originWeatherRaw = widget.routeData['weather_origin'];
    final List<dynamic>? originWeather = (originWeatherRaw is List && originWeatherRaw.isNotEmpty) ? originWeatherRaw : null;

    final double finalDistanceInMeters = _getFinalDistance();
    final bool showFinalStep = finalDistanceInMeters > 300;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: _saveRoute,
              tooltip: "Save Route",
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: const CameraPosition(
                target: LatLng(14.2121, 121.1687),
                zoom: 12,
              ),
              polylines: _polylines,
              // --- MERGE Route Markers + Incident Markers ---
              markers: _markers.union(_incidentMarkers),
              padding: const EdgeInsets.only(bottom: 200),
              onMapCreated: (GoogleMapController controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                _zoomToRoute();
              },
            ),
          ),

          // --- THE DRAGGABLE SHEET ---
          DraggableScrollableSheet(
            initialChildSize: 0.40,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))
                  ],
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // --- MODIFIED HEADER ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start, // Align top
                        children: [
                          // Left: Time & Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  widget.routeData['total_time_formatted'] ?? '',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (context) => FareBreakdownSheet(routeData: widget.routeData),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  children: [
                                    Text(
                                        widget.routeData['total_fare_formatted'] ?? '',
                                        style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.info_outline, size: 16, color: Colors.green),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Right: Weather Button
                          if (destWeather != null)
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => WeatherForecastSheet(
                                    originName: "Start",
                                    destinationName: "Destination",
                                    originWeather: originWeather,
                                    destWeather: destWeather,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(_getEmoji(destWeather[0]['condition']), style: const TextStyle(fontSize: 22)),
                                    const Text("Forecast", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),

                    // --- DIRECTIONS LIST ---
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: legs.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            String startName = "Your Location";
                            if (legs.isNotEmpty) {
                              final firstLeg = Map<String, dynamic>.from(legs.first as Map);
                              startName = firstLeg['start_stop_name'] ?? "Your Location";
                            }
                            return _buildStepTile(
                              icon: Icons.my_location,
                              color: Colors.green,
                              title: "Start at $startName",
                              subtitle: "Walk to the first stop",
                            );
                          }

                          if (index == legs.length + 1) {
                            return _buildStepTile(
                              icon: Icons.location_on,
                              color: Colors.red,
                              title: "Arrive at Destination",
                              subtitle: "You have reached your destination.",
                            );
                          }

                          final int legIndex = index - 1;
                          final leg = Map<String, dynamic>.from(legs[legIndex] as Map);
                          String stopName = leg['end_stop_name'] ?? "";
                          if (stopName.contains("Flag Down") || stopName.contains("Virtual") || stopName.contains("Drop off")) {
                            stopName = "Roadside (Wait for next ride)";
                          }
                          List<dynamic> placards = leg['placards'] ?? [];

                          return _buildSmartLegTile(
                            leg: leg,
                            placards: placards,
                            stopName: stopName,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmartLegTile({
    required Map<String, dynamic> leg,
    required List<dynamic> placards,
    required String stopName,
  }) {
    String type = (leg['route_type'] ?? '').toString().toUpperCase();
    bool isWalk = type == 'WALK';
    bool isTricycle = type.contains('TRICYCLE');
    IconData icon = isWalk ? Icons.directions_walk :
    isTricycle ? Icons.electric_rickshaw : Icons.directions_bus;
    Color color = isWalk ? Colors.grey :
    isTricycle ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0,2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 40,
                width: 2,
                decoration: BoxDecoration(color: Colors.grey.shade300),
              )
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg['display_name'] ?? "Travel",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (!isWalk && !isTricycle && placards.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text("Look for Signboard:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Wrap(
                    spacing: 4,
                    children: placards.map((text) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        text.toString().toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "${leg['time_minutes'].round()} mins • ${leg['distance_km'].toStringAsFixed(1)} km",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (leg['traffic_status'] == 'HEAVY') ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, color: Colors.red, size: 8),
                      Text(" Heavy Traffic", style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text("Get off at: $stopName", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  String _getEmoji(String? condition) {
    if (condition == null) return "";
    if (condition.contains("Rain")) return "🌧️";
    if (condition.contains("Cloud")) return "☁️";
    if (condition.contains("Clear")) return "☀️";
    if (condition.contains("Thunder")) return "⛈️";
    return "🌤️";
  }
}

// --- HELPER ---
List<LatLng> _decodePolyline(String encoded) {
  List<LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    points.add(LatLng(lat / 1E5, lng / 1E5));
  }
  return points;
}