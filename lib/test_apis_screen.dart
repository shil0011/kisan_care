import 'package:flutter/material.dart';
import 'services/weather_service.dart';
import 'services/market_price_service.dart';
import 'services/location_service.dart';
import 'config/app_theme.dart';

class TestApisScreen extends StatefulWidget {
  const TestApisScreen({super.key});

  @override
  State<TestApisScreen> createState() => _TestApisScreenState();
}

class _TestApisScreenState extends State<TestApisScreen> {
  final _weatherService = WeatherService();
  final _marketService = MarketPriceService();
  final _locationService = LocationService();
  
  String _locationStatus = '⏳ Testing...';
  String _weatherStatus = '⏳ Testing...';
  String _marketStatus = '⏳ Testing...';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() => _isLoading = true);
    
    // Test Location
    try {
      final location = await _locationService.getLocationInfo();
      if (location != null) {
        setState(() {
          _locationStatus = '✅ Location: ${location['address']}\n'
              'Coordinates: ${location['latitude']}, ${location['longitude']}';
        });
      } else {
        setState(() {
          _locationStatus = '❌ Location service failed - check permissions';
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = '❌ Location error: $e';
      });
    }
    
    // Test Weather
    try {
      // Test with Pune coordinates
      final weather = await _weatherService.getCurrentWeather(18.5204, 73.8567);
      if (weather != null) {
        final formatted = _weatherService.formatWeatherData(weather, 'English');
        setState(() {
          _weatherStatus = '✅ Weather API working!\n'
              'Location: ${weather['name']}\n'
              'Temperature: ${weather['main']['temp']}°C\n'
              'Condition: ${weather['weather'][0]['description']}\n\n'
              'Formatted:\n$formatted';
        });
      } else {
        setState(() {
          _weatherStatus = '❌ Weather API failed - check API key';
        });
      }
    } catch (e) {
      setState(() {
        _weatherStatus = '❌ Weather error: $e';
      });
    }
    
    // Test Market Price
    try {
      final prices = await _marketService.getMarketPrices(
        commodity: 'Tomato',
        limit: 3,
      );
      if (prices != null && prices['records'] != null) {
        final records = prices['records'] as List;
        final formatted = _marketService.formatMarketPriceData(prices, 'English');
        setState(() {
          _marketStatus = '✅ Market Price API working!\n'
              'Found ${records.length} records for Tomato\n\n'
              'Formatted:\n$formatted';
        });
      } else {
        setState(() {
          _marketStatus = '❌ Market Price API failed - check API key';
        });
      }
    } catch (e) {
      setState(() {
        _marketStatus = '❌ Market Price error: $e';
      });
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Tests'),
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTestCard('1️⃣ Location Service', _locationStatus),
                const SizedBox(height: 16),
                _buildTestCard('2️⃣ Weather Service', _weatherStatus),
                const SizedBox(height: 16),
                _buildTestCard('3️⃣ Market Price Service', _marketStatus),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📝 Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('✅ = API is working correctly'),
                        Text('❌ = API has issues'),
                        SizedBox(height: 8),
                        Text(
                          'If all tests pass, the app is ready to use!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTestCard(String title, String status) {
    final isSuccess = status.startsWith('✅');
    final isError = status.startsWith('❌');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : isError ? Icons.error : Icons.hourglass_empty,
                  color: isSuccess ? Colors.green : isError ? Colors.red : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                status,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
