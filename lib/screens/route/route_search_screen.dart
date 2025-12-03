import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travelbuddy_final/screens/route/result_screen.dart';
import 'package:travelbuddy_final/utils/api_keys.dart';

class RouteSearchScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialName;
  final bool isStart;

  const RouteSearchScreen({
    Key? key,
    this.initialLocation,
    this.initialName,
    this.isStart = true,
  }) : super(key: key);

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final _startSearchController = TextEditingController();
  final _endSearchController = TextEditingController();
  LatLng? _startLocationCoords;
  LatLng? _endLocationCoords;

  List<bool> _trafficSelection = [true, false];
  String _trafficOption = "Normal";

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null && widget.initialName != null) {
      if (widget.isStart) {
        _startLocationCoords = widget.initialLocation;
        _startSearchController.text = widget.initialName!;
      } else {
        _endLocationCoords = widget.initialLocation;
        _endSearchController.text = widget.initialName!;
      }
    }
  }

  // --- HELPER: Get Current Location ---
  Future<void> _useCurrentLocation() async {
    try {
      // FIXED: Geolocator now works because we added the import
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _startSearchController.text = "Your Current Location";
        _startLocationCoords = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not get current location")),
      );
    }
  }

  void _swapLocations() {
    setState(() {
      final tempText = _startSearchController.text;
      final tempCoords = _startLocationCoords;
      _startSearchController.text = _endSearchController.text;
      _startLocationCoords = _endLocationCoords;
      _endSearchController.text = tempText;
      _endLocationCoords = tempCoords;
    });
  }

  void _searchRoutes() {
    if (_startLocationCoords == null || _endLocationCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both origin and destination')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          startLocation: _startLocationCoords!,
          endLocation: _endLocationCoords!,
          trafficOption: _trafficOption,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Find Routes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where do you want to go?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            // --- INPUT SECTION ---
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // FROM CARD (With Location Button)
                      Stack(
                        children: [
                          _buildInputCard(
                            controller: _startSearchController,
                            hint: "Origin (e.g. Balibago)",
                            icon: Icons.my_location,
                            themeColor: Colors.blue,
                            isStart: true,
                            label: "FROM",
                          ),
                          Positioned(
                            right: 16,
                            top: 28,
                            child: InkWell(
                              onTap: _useCurrentLocation,
                              child: const Icon(Icons.gps_fixed, color: Colors.blue, size: 20),
                            ),
                          ),
                        ],
                      ),

                      // TO CARD
                      _buildInputCard(
                        controller: _endSearchController,
                        hint: "Destination (e.g. Batangas Pier)",
                        icon: Icons.location_on,
                        themeColor: Colors.red,
                        isStart: false,
                        label: "TO",
                      ),
                    ],
                  ),

                  // FLOATING SWAP BUTTON
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: InkWell(
                      onTap: _swapLocations,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Icon(Icons.swap_vert, color: Color(0xFF2196F3), size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- DEPARTURE & TRAFFIC ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Departure Time", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54, fontSize: 16)),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(11),
                    isSelected: _trafficSelection,
                    onPressed: (index) {
                      setState(() {
                        for (int i = 0; i < _trafficSelection.length; i++) {
                          _trafficSelection[i] = i == index;
                        }
                        _trafficOption = index == 0 ? "Normal" : "RushHour";
                      });
                    },
                    fillColor: const Color(0xFF2196F3),
                    selectedColor: Colors.white,
                    color: Colors.black54,
                    renderBorder: false,
                    constraints: const BoxConstraints(minWidth: 90, minHeight: 40),
                    children: const [
                      Text("Now", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text("Rush Hour", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- SEARCH BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _searchRoutes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: Colors.blue.withOpacity(0.4),
                ),
                child: const Text(
                    'Find Routes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- TIPS CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      const Text("Travel Tips", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("• Select specific barangays for better accuracy.", style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const Text("• Check traffic conditions (Now vs Rush Hour).", style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const Text("• Have exact fare ready.", style: TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- THE HELPER WIDGET  ---
  Widget _buildInputCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color themeColor,
    required bool isStart,
    required String label,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400])),
              const SizedBox(height: 4),
              Icon(icon, color: themeColor, size: 26),
            ],
          ),
          const SizedBox(width: 20),

          Expanded(
            child: GooglePlacesAutoCompleteTextFormField(
              textEditingController: controller,
              config: GoogleApiConfig(
                apiKey: googleMapsApiKey,
                countries: const ["ph"],
                fetchPlaceDetailsWithCoordinates: true,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: themeColor, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              onPredictionWithCoordinatesReceived: (prediction) {
                if (prediction.lat != null && prediction.lng != null) {
                  setState(() {
                    final lat = double.parse(prediction.lat!);
                    final lng = double.parse(prediction.lng!);
                    if (isStart) {
                      _startLocationCoords = LatLng(lat, lng);
                    } else {
                      _endLocationCoords = LatLng(lat, lng);
                    }
                  });
                }
              },
              onSuggestionClicked: (prediction) {
                controller.text = prediction.description ?? "";
                controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              },
            ),
          ),
        ],
      ),
    );
  }
}