import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:travelbuddy_final/screens/route/route_details_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travelbuddy_final/widgets/route_ticket_card.dart';

class ResultsScreen extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String trafficOption;

  const ResultsScreen({
    super.key,
    required this.startLocation,
    required this.endLocation,
    required this.trafficOption,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Future<List<dynamic>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = _callFindRoutes();
  }

  Future<List<dynamic>> _callFindRoutes() async {
    try {
      HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('findRoutes');
      final result = await callable.call(<String, dynamic>{
        'startLat': widget.startLocation.latitude,
        'startLng': widget.startLocation.longitude,
        'endLat': widget.endLocation.latitude,
        'endLng': widget.endLocation.longitude,
        'traffic': widget.trafficOption,
      });
      return result.data['routes'] as List<dynamic>;
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Function Error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      print('Generic Error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Available Routes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _routesFuture,
        builder: (context, snapshot) {

          // 1. LOADING STATE
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('Calculating optimal paths...', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Checking traffic & weather...', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            );
          }

          // 2. ERROR STATE
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text('Oops! Something went wrong.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _routesFuture = _callFindRoutes(); // Retry
                        });
                      },
                      child: const Text("Try Again"),
                    )
                  ],
                ),
              ),
            );
          }

          // 3. EMPTY STATE
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No routes found.', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Try moving your pins slightly closer to a main road.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. SUCCESS LIST
          final routes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              // Sanity check
              if (route['legs'] == null || (route['legs'] as List).isEmpty) {
                return const SizedBox.shrink();
              }

              // Render the Pro Ticket Card
              return RouteTicketCard(
                routeData: route,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        routeData: route,
                        finalDestination: widget.endLocation,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}