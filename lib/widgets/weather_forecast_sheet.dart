import 'package:flutter/material.dart';

class WeatherForecastSheet extends StatelessWidget {
  final String originName;
  final String destinationName;
  final List<dynamic>? originWeather;
  final List<dynamic>? destWeather;

  const WeatherForecastSheet({
    super.key,
    required this.originName,
    required this.destinationName,
    required this.originWeather,
    required this.destWeather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "🌤️ Trip Forecast",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Weather prediction for the next 9 hours.",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // The Columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Origin Column
              Expanded(
                child: _buildCityColumn(
                    context,
                    "Start: $originName",
                    originWeather
                ),
              ),
              const SizedBox(width: 16),
              // Divider
              Container(width: 1, height: 150, color: Colors.grey[300]),
              const SizedBox(width: 16),
              // Destination Column
              Expanded(
                child: _buildCityColumn(
                    context,
                    "End: $destinationName",
                    destWeather
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[50],
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityColumn(BuildContext context, String title, List<dynamic>? weatherList) {
    if (weatherList == null || weatherList.isEmpty) {
      return Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          const Text("No data", style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),

        // LIMIT TO 3 ITEMS (9 Hours)
        ...weatherList.take(3).map((w) {
          // Get the description (e.g. "light rain")
          String desc = w['description'] ?? w['condition'] ?? '';
          desc = _toTitleCase(desc);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                // 1. Time (e.g. 2 PM)
                SizedBox(
                  width: 50,
                  child: Text(
                      w['time_label'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)
                  ),
                ),

                // 2. Emoji
                Text(_getEmoji(w['condition'] ?? ''), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),

                // 3. Description (The Google Style text)
                Expanded(
                  child: Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[800], fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // 4. Temp
                Text("${w['temp_celsius']}°", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- HELPER: Capitalize First Letters (light rain -> Light Rain) ---
  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _getEmoji(String condition) {
    if (condition.contains("Rain")) return "🌧️";
    if (condition.contains("Cloud")) return "☁️";
    if (condition.contains("Clear")) return "☀️";
    if (condition.contains("Thunder")) return "⛈️";
    return "🌤️";
  }
}