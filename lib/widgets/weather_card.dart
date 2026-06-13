import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class WeatherCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? language;

  const WeatherCard({super.key, required this.data, this.language});

  @override
  Widget build(BuildContext context) {
    // Basic data extraction
    final location = (data['location'] ?? data['name'] ?? 'Unknown').toString();
    final currentTemp = data['currentTemp']?.toString() ?? '--';
    final conditionStr = data['condition']?.toString() ?? 'Sunny';
    final humidity = data['humidity']?.toString() ?? '--';
    final wind = data['wind']?.toString() ?? '--';
    final summary = data['summary']?.toString() ?? '';
    final forecast = (data['forecast'] as List?) ?? [];
    final hourly = (data['hourly'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Green Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF569451),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Text(
                'Location: ${location.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getWeatherIcon(conditionStr), size: 80, color: const Color(0xFFFFD180)),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentTemp°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          height: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_getConditionText(conditionStr)} Skies',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Inner Box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(Icons.water_drop, '$humidity%', 'Humidity'),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildStat(Icons.air, '$wind km/h', 'Wind'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        // Farming Advice
        if (summary.isNotEmpty) ...[
          const Text(
            'Farming Advice',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.aiBubbleGrey,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E6E26),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFA5E6A1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.agriculture, color: Color(0xFF1E6E26), size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _getAIRecommendationText(language),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            summary.replaceAll('💡 Recommendation:', '').trim(),
                            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Hourly Forecast
        if (hourly.isNotEmpty) ...[
          const Text(
            'Hourly Forecast',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hourly.length,
              itemBuilder: (context, index) {
                final h = hourly[index];
                final isSelected = index == 1; // Arbitrary selected index to match design logic
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E6E26) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        h['time']?.toString() ?? '',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Icon(
                        _getWeatherIcon(h['condition']),
                        color: isSelected ? const Color(0xFFFFD180) : const Color(0xFFD68A1A),
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${h['temp']}°',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],

        // 5-Day Outlook
        if (forecast.isNotEmpty) ...[
          Text(
            _get5DayOutlookText(language),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: forecast.map((day) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        day['day']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getWeatherIcon(day['condition']), color: const Color(0xFFD68A1A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _capitalize(day['condition']?.toString() ?? ''),
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${day['temp']}°',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _getConditionText(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('cloud')) return 'Cloudy';
    if (lower.contains('sun') || lower.contains('clear')) return 'Clear';
    if (lower.contains('rain')) return 'Rainy';
    return _capitalize(condition);
  }

  IconData _getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear':
      case 'sunny':
      case 'sun':
        return Icons.wb_sunny;
      case 'clouds':
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
      case 'rainy':
        return Icons.water_drop;
      default:
        return Icons.wb_cloudy;
    }
  }

  String _getAIRecommendationText(String? language) {
    if (language == null || language.contains('English')) return 'AI Recommendation';
    if (language.contains('Hindi') || language.contains('हिन्दी')) return 'एआई सिफारिश';
    if (language.contains('Bengali') || language.contains('বাংলা')) return 'এআই সুপারিশ';
    if (language.contains('Telugu') || language.contains('తెలుగు')) return 'AI సిఫార్సు';
    if (language.contains('Marathi') || language.contains('मराठी')) return 'एआय शिफारस';
    if (language.contains('Tamil') || language.contains('தமிழ்')) return 'AI பரிந்துரை';
    if (language.contains('Gujarati') || language.contains('ગુજરાતી')) return 'AI ભલામણ';
    if (language.contains('Kannada') || language.contains('ಕನ್ನಡ')) return 'AI ಶಿಫಾರಸು';
    if (language.contains('Malayalam') || language.contains('മലയാളം')) return 'AI ശുപാർശ';
    if (language.contains('Punjabi') || language.contains('ਪੰਜਾਬੀ')) return 'AI ਸਿਫ਼ਾਰਸ਼';
    return 'AI Recommendation';
  }

  String _get5DayOutlookText(String? language) {
    if (language == null || language.contains('English')) return '5-Day Outlook';
    if (language.contains('Hindi') || language.contains('हिन्दी')) return '5-दिन का पूर्वानुमान';
    if (language.contains('Bengali') || language.contains('বাংলা')) return '৫-দিনের পূর্বাভাস';
    if (language.contains('Telugu') || language.contains('తెలుగు')) return '5-రోజుల అవుట్‌లుక్';
    if (language.contains('Marathi') || language.contains('मराठी')) return '5-दिवसांचा अंदाज';
    if (language.contains('Tamil') || language.contains('தமிழ்')) return '5-நாள் கண்ணோட்டம்';
    if (language.contains('Gujarati') || language.contains('ગુજરાતી')) return '5-દિવસનો દૃષ્ટિકોણ';
    if (language.contains('Kannada') || language.contains('ಕನ್ನಡ')) return '5-ದಿನಗಳ ದೃಷ್ಟಿಕೋನ';
    if (language.contains('Malayalam') || language.contains('മലയാളം')) return '5-ദിവസ വീക്ഷണം';
    if (language.contains('Punjabi') || language.contains('ਪੰਜਾਬੀ')) return '5-ਦਿਨ ਦਾ ਦ੍ਰਿਸ਼ਟੀਕੋਣ';
    return '5-Day Outlook';
  }
}
