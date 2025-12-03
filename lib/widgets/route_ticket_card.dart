import 'package:flutter/material.dart';
import 'package:travelbuddy_final/utils/app_colors.dart';
import 'package:travelbuddy_final/widgets/weather_forecast_sheet.dart';

class RouteTicketCard extends StatelessWidget {
  final dynamic routeData;
  final VoidCallback onTap;

  const RouteTicketCard({super.key, required this.routeData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> legs = routeData['legs'];
    final String totalTime = routeData['total_time_formatted'];
    final String totalFare = routeData['total_fare_formatted'];

    // 1. Parse Weather Data
    final originWeatherRaw = routeData['weather_origin'];
    final destWeatherRaw = routeData['weather_destination'];
    final List<dynamic>? originWeather = originWeatherRaw is List ? originWeatherRaw : null;
    final List<dynamic>? destWeather = destWeatherRaw is List ? destWeatherRaw : null;

    // 2. Analyze Traffic
    bool isHeavyTraffic = false;
    bool isModerateTraffic = false;

    for (var legRaw in legs) {
      final leg = Map<String, dynamic>.from(legRaw as Map);
      if (leg['traffic_status'] == 'HEAVY') isHeavyTraffic = true;
      if (leg['traffic_status'] == 'MODERATE') isModerateTraffic = true;
    }

    Color trafficColor = AppColors.trafficLow;
    String trafficText = "Smooth";
    if (isHeavyTraffic) {
      trafficColor = AppColors.trafficHeavy;
      trafficText = "Heavy Traffic";
    } else if (isModerateTraffic) {
      trafficColor = AppColors.trafficModerate;
      trafficText = "Moderate";
    }

    // 3. FIND THE MAIN VEHICLE
    Map<String, dynamic>? mainLeg;
    List<dynamic> placards = [];

    for (var legRaw in legs) {

      final leg = Map<String, dynamic>.from(legRaw as Map);

      String type = (leg['route_type'] ?? '').toString().toUpperCase();
      if (type != 'WALK' && type != 'TRICYCLE_RIDE') {
        mainLeg = leg;
        placards = leg['placards'] ?? [];
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(totalTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.0)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trafficColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: trafficColor),
                              const SizedBox(width: 6),
                              Text(trafficText, style: TextStyle(color: trafficColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Weather Button
                    if (destWeather != null && destWeather.isNotEmpty)
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(_getEmoji(destWeather[0]['condition']), style: const TextStyle(fontSize: 20)),
                              const Text("Forecast", style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // --- MIDDLE: SIGNBOARDS (PLACARDS) ---
                if (mainLeg != null) ...[
                  Row(
                    children: [
                      Icon(AppColors.getIconByType(mainLeg['route_type']), size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Ride ${mainLeg['route_type']} via:",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // THE YELLOW PLACARDS
                  if (placards.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: placards.map((text) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.yellow[700], // Jeepney Yellow
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0,1))]
                        ),
                        child: Text(
                          text.toString().toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.black87),
                        ),
                      )).toList(),
                    )
                  else
                    Text(
                      mainLeg['route_name'] ?? 'Unknown Route',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                ] else ...[
                  Row(
                    children: const [
                      Icon(Icons.directions_walk, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("Walk Direct to Destination", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                ],

                const SizedBox(height: 16),

                // --- BOTTOM: PRICE & TIMELINE ICONS ---
                Row(
                  children: [
                    // Price Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(totalFare, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),

                    const Spacer(),

                    // Tiny Icons Timeline
                    Row(
                      children: legs.map<Widget>((legRaw) {
                        // FIX: CAST HERE TOO
                        final leg = Map<String, dynamic>.from(legRaw as Map);

                        final String type = leg['route_type'] ?? 'WALK';
                        final Color color = AppColors.getColorByType(type);
                        final bool isHeavy = leg['traffic_status'] == 'HEAVY';

                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                              AppColors.getIconByType(type),
                              size: 18,
                              color: isHeavy ? AppColors.trafficHeavy : color
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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