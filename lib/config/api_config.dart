import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Gemini API key from https://aistudio.google.com/app/apikey
  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY', fallback: '');
  
  // OpenWeatherMap API key - Get from https://openweathermap.org/api
  static String get openWeatherApiKey => dotenv.get('OPEN_WEATHER_API_KEY', fallback: '');
  
  // OGD (Open Government Data) API key from data.gov.in
  static String get ogdApiKey => dotenv.get('OGD_API_KEY', fallback: '');
  
  // Development Note:
  // API keys are now securely loaded from the .env file.
  // Make sure .env is added to your assets in pubspec.yaml and excluded in .gitignore.
}
