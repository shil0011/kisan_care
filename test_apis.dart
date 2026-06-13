import 'package:kisancare/services/weather_service.dart';
import 'package:kisancare/services/market_price_service.dart';
import 'package:kisancare/services/location_service.dart';

void main() async {
  print('🧪 Testing KisanCare APIs...\n');
  
  // Test 1: Location Service
  print('1️⃣ Testing Location Service...');
  final locationService = LocationService();
  try {
    final location = await locationService.getLocationInfo();
    if (location != null) {
      print('✅ Location: ${location['address']}');
      print('   Coordinates: ${location['latitude']}, ${location['longitude']}');
    } else {
      print('❌ Location service failed - check permissions');
    }
  } catch (e) {
    print('❌ Location error: $e');
  }
  print('');
  
  // Test 2: Weather Service
  print('2️⃣ Testing Weather Service...');
  final weatherService = WeatherService();
  try {
    // Test with Pune coordinates
    final weather = await weatherService.getCurrentWeather(18.5204, 73.8567);
    if (weather != null) {
      print('✅ Weather API working!');
      print('   Location: ${weather['name']}');
      print('   Temperature: ${weather['main']['temp']}°C');
      print('   Condition: ${weather['weather'][0]['description']}');
      
      // Test formatting
      final formatted = weatherService.formatWeatherData(weather, 'English');
      print('\n   Formatted (English):');
      print(formatted);
      
      final formattedHindi = weatherService.formatWeatherData(weather, 'Hindi');
      print('   Formatted (Hindi):');
      print(formattedHindi);
    } else {
      print('❌ Weather API failed - check API key');
    }
  } catch (e) {
    print('❌ Weather error: $e');
  }
  print('');
  
  // Test 3: Market Price Service
  print('3️⃣ Testing Market Price Service...');
  final marketService = MarketPriceService();
  try {
    final prices = await marketService.getMarketPrices(
      commodity: 'Tomato',
      limit: 3,
    );
    if (prices != null && prices['records'] != null) {
      final records = prices['records'] as List;
      print('✅ Market Price API working!');
      print('   Found ${records.length} records for Tomato');
      
      if (records.isNotEmpty) {
        final formatted = marketService.formatMarketPriceData(prices, 'English');
        print('\n   Formatted (English):');
        print(formatted);
        
        final formattedHindi = marketService.formatMarketPriceData(prices, 'Hindi');
        print('   Formatted (Hindi):');
        print(formattedHindi);
      }
    } else {
      print('❌ Market Price API failed - check API key or commodity name');
    }
  } catch (e) {
    print('❌ Market Price error: $e');
  }
  print('');
  
  print('🎉 API Testing Complete!');
  print('\n📝 Summary:');
  print('   - If all tests passed: APIs are configured correctly');
  print('   - If Weather failed: Check OpenWeatherMap API key');
  print('   - If Market Price failed: Check OGD API key');
  print('   - If Location failed: Enable location permissions');
}
