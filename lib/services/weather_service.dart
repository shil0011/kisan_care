import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get current weather by coordinates
  Future<Map<String, dynamic>?> getCurrentWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=${ApiConfig.openWeatherApiKey}&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  // Get weather forecast
  Future<Map<String, dynamic>?> getWeatherForecast(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=${ApiConfig.openWeatherApiKey}&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Forecast API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      return null;
    }
  }

  // Format weather data for display
  String formatWeatherData(Map<String, dynamic> data, String language) {
    try {
      final temp = data['main']['temp'].toStringAsFixed(1);
      final feelsLike = data['main']['feels_like'].toStringAsFixed(1);
      final humidity = data['main']['humidity'];
      final description = data['weather'][0]['description'];
      final windSpeed = data['wind']['speed'];
      final location = data['name'];

      if (language.contains('Hindi') || language.contains('हिन्दी')) {
        return '''
मौसम की जानकारी - $location

🌡️ तापमान: ${temp}°C
🤚 महसूस होता है: ${feelsLike}°C
💧 आर्द्रता: $humidity%
🌤️ स्थिति: $description
💨 हवा: ${windSpeed} m/s
''';
      } else {
        return '''
Weather Information - $location

🌡️ Temperature: ${temp}°C
🤚 Feels like: ${feelsLike}°C
💧 Humidity: $humidity%
🌤️ Condition: $description
💨 Wind: ${windSpeed} m/s
''';
      }
    } catch (e) {
      return 'Error formatting weather data';
    }
  }
}
