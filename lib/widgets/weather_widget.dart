import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../models/weather.dart';
import '../utils/constants.dart';

class WeatherWidget extends StatefulWidget {
  final WeatherService weatherService;
  final LocationService locationService;

  const WeatherWidget({
    Key? key,
    required this.weatherService,
    required this.locationService,
  }) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Weather? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final position = await widget.locationService.getCurrentLocation();
    final weather = await widget.weatherService.getWeather(
      position?.latitude ?? AppConstants.defaultLat,
      position?.longitude ?? AppConstants.defaultLng,
    );

    if (mounted) {
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : _weather == null
            ? const Center(
          child: Text(
            'Weather data unavailable',
            style: TextStyle(color: Colors.white),
          ),
        )
            : Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weather',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_weather!.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _weather!.description.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_weather!.humidity}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.air,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_weather!.windSpeed.toStringAsFixed(1)} m/s',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              _getWeatherIcon(_weather!.description),
              size: 64,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('cloud')) return Icons.cloud;
    if (desc.contains('rain')) return Icons.umbrella;
    if (desc.contains('sun') || desc.contains('clear')) return Icons.wb_sunny;
    if (desc.contains('storm')) return Icons.thunderstorm;
    return Icons.wb_cloudy;
  }
}
