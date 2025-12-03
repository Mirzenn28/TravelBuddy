import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../utils/constants.dart';

class WeatherService {
  Future<Weather?> getWeather(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&units=metric&appid=${AppConstants.openWeatherMapApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return Weather.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
    return null;
  }

  Future<List<Weather>> getForecast(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lng&units=metric&appid=${AppConstants.openWeatherMapApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Weather> forecasts = [];

        for (var item in data['list'].take(5)) {
          forecasts.add(Weather.fromJson(item));
        }

        return forecasts;
      }
    } catch (e) {
      print('Error fetching forecast: $e');
    }
    return [];
  }
}
