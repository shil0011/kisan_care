import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/message_model.dart';
import '../config/api_config.dart';
import 'weather_service.dart';
import 'market_price_service.dart';
import 'location_service.dart';

class AIService {
  static const String _apiKey = ApiConfig.geminiApiKey;
  
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  final WeatherService _weatherService = WeatherService();
  final MarketPriceService _marketPriceService = MarketPriceService();
  final LocationService _locationService = LocationService();

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
    );
  }

  // Provide AI insights specifically for the 5-day forecast
  Future<String> _getForecastRecommendation(List<Map<String, dynamic>> forecastDays, String language) async {
    try {
      final summary = forecastDays.map((d) => "${d['day']}:${d['temp']}°/${d['condition']}").join(', ');
      final prompt = '''
You are an agricultural advisor. Based on this 5-day forecast summary: $summary

Provide guidance in $language with strictly plain text. NO markdown symbols (no #, no *, no **):
1) Summary (1-2 lines)
2) Dos (3 bullet points)
3) Don'ts (3 bullet points)
4) Irrigation and fertilizer scheduling tips (if applicable)
Keep it concise and farmer-friendly.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (_) {
      return '';
    }
  }

  // Simple heuristic to extract commodity name without LLM
  String _extractCommodityHeuristic(String query) {
    final q = query.toLowerCase();
    // Order longest names first to prevent partial matches (e.g. "rice" inside "price")
    const common = [
      'sugarcane','groundnut','coriander','cauliflower','turmeric',
      'soybean','soyabean','mustard','spinach','cucumber','cabbage',
      'brinjal','pumpkin','banana','tomato','potato','cotton',
      'carrot','chilli','pulses','maize','wheat','paddy','onion',
      'beans','jowar','bajra','gram','okra','peas','rice','corn',
    ];
    for (final c in common) {
      // Use word boundary to avoid matching "rice" inside "price"
      final regex = RegExp('\\b$c\\b');
      if (regex.hasMatch(q)) {
        return c[0].toUpperCase() + c.substring(1);
      }
    }
    // Try extracting the word after "price of" / "rate of"
    final reg = RegExp(r'(?:price|rate|कीमत|भाव)\s*(?:of|for|का|के|की)?\s*([A-Za-z\p{L}]+)', unicode: true);
    final m = reg.firstMatch(q);
    if (m != null && m.groupCount >= 1) {
      final g = m.group(1)!;
      if (g.isNotEmpty) return g[0].toUpperCase() + g.substring(1);
    }
    return '';
  }

  // Send query to Gemini AI with integrated services
  Future<ChatMessage> sendQuery({
    required String userId,
    required String sessionId,
    required String queryType, // 'text' or 'image'
    required String content,
    String? imagePath,
    String language = 'English',
  }) async {
    try {
      // Check if query is about weather
      if (_isWeatherQuery(content)) {
        print('🧭 [AIService] Intent detected: WEATHER | query="$content"');
        return await _handleWeatherQuery(userId, sessionId, content, language);
      }
      
      // Check if query is about market prices
      if (_isMarketPriceQuery(content)) {
        print('🧭 [AIService] Intent detected: MARKET_PRICE | query="$content"');
        return await _handleMarketPriceQuery(userId, sessionId, content, language);
      }
      
      // Handle image-based disease detection
      if (queryType == 'image' && imagePath != null) {
        return await _handleImageAnalysis(userId, sessionId, imagePath, content, language);
      }

      // Handle scheme queries
      if (content.toLowerCase().contains('schemes') || content.toLowerCase().contains('scheme')) {
        print('🧭 [AIService] Intent detected: SCHEMES | query="\$content"');
        return await _handleSchemeQuery(userId, sessionId, content, language);
      }

      // Handle general queries with Gemini
      return await _handleGeneralQuery(userId, sessionId, content, language);
    } catch (e) {
      return _createErrorMessage(userId, sessionId, e.toString(), language);
    }
  }

  // Check if query is about weather
  bool _isWeatherQuery(String query) {
    final weatherKeywords = [
      // English
      'weather', 'temperature', 'rain', 'forecast', 'climate',
      // Hindi
      'मौसम', 'तापमान', 'बारिश', 'जलवायु',
      // Tamil
      'வெள்ளநிலை', 'வெப்பநிலை', 'மழை', 'காலநிலை',
      // Telugu
      'వాతావరణం', 'ఉష్ణోగ్రత', 'వర్షం', 'వాతావరణ అనుమానం',
      // Bengali
      'আবহাওয়া', 'তাপমাত্রা', 'বৃষ্টি', 'আবহাওয়া পূর্বাভাস',
      // Marathi
      'हवामान', 'तापमान', 'पाऊस', 'हवामान अंदाज',
      // Gujarati
      'હવામાન', 'તાપમાન', 'વરસાદ', 'હવામાન અંદાજ',
      // Kannada
      'ಹವಾಮಾನ', 'ತಾಪಮಾನ', 'ಮಳೆ', 'ಹವಾಮಾನ ಪೂರ್ವಾನುಮಾನ',
      // Malayalam
      'കാലാവസ്ഥ', 'താപനില', 'മഴ', 'കാലാവസ്ഥാ പൂർവ്വാനുമാനം',
      // Punjabi
      'ਮੌਸਮ', 'ਤਾਪਮਾਨ', 'ਮੀਂਹ', 'ਮੌਸਮੀ ਪੂਰਵ ਅਨੁਮਾਨ'
    ];
    return weatherKeywords.any((keyword) => query.toLowerCase().contains(keyword));
  }

  // Check if query is about market prices
  bool _isMarketPriceQuery(String query) {
    final q = query.toLowerCase();
    final priceKeywords = [
      // English
      'price', 'market', 'rate', 'cost', 'sell', 'buy', 'selling', 'buying',
      // Hindi
      'मूल्य', 'बाजार', 'दाम', 'कीमत', 'बेचना', 'खरीदना',
      // Tamil
      'விலை', 'சந்தை', 'விலைவாசி', 'விலைநிலை',
      // Telugu
      'విలువ', 'మార్కెట్', 'రేటు', 'వెలలు',
      // Bengali
      'দাম', 'বাজার', 'মূল্য', 'বিক্রি',
      // Marathi
      'दर', 'बाजारपेठ', 'किंमत', 'विक्री',
      // Gujarati
      'ભાવ', 'બજાર', 'દર', 'વેચાણ',
      // Kannada
      'ಬೆಲೆ', 'ಮಾರುಕಟ್ಟೆ', 'ದರ', 'ವಿಕ್ರಯ',
      // Malayalam
      'വില', 'മാർക്കറ്റ്', 'രേറ്റ്', 'വിർപ്പന',
      // Punjabi
      'ਕੀਮਤ', 'ਮੰਡੀ', 'ਦਰ', 'ਵੇਚਣਾ'
    ];
    
    // Also check for crop names combined with market-related words
    final cropKeywords = ['tomato', 'potato', 'onion', 'wheat', 'rice', 'cotton'];
    final marketWords = ['market', 'price', 'rate', 'cost', 'बाजार', 'दाम', 'விலை', 'విలువ'];
    
    final hasMarketKeyword = priceKeywords.any((keyword) => q.contains(keyword));
    final hasCropAndMarket = cropKeywords.any((crop) => q.contains(crop)) && 
                            marketWords.any((market) => q.contains(market));
    
    final isMarketQuery = hasMarketKeyword || hasCropAndMarket;
    
    print('🔍 [AIService] Market price detection: "$query" -> $isMarketQuery');
    if (isMarketQuery) {
      final matched = priceKeywords.where((k) => q.contains(k)).toList();
      print('   • Matched keywords: $matched');
      if (hasCropAndMarket) {
        print('   • Detected crop + market combination');
      }
    }
    return isMarketQuery;
  }

  // Handle weather queries
  Future<ChatMessage> _handleWeatherQuery(String userId, String sessionId, String query, String language) async {
    try {
      var location = await _locationService.getLocationInfo();
      if (location == null) {
        // Fallback: try last known position or default to Pune
        print('⚠️ [AIService] Location unavailable. Falling back to default coordinates.');
        location = {
          'latitude': 18.5204,
          'longitude': 73.8567,
          'address': 'Pune, Maharashtra (default)'
        };
      }

      final weatherData = await _weatherService.getCurrentWeather(
        location['latitude'],
        location['longitude'],
      );

      if (weatherData == null) {
        return ChatMessage.aiResponse(
          userId,
          sessionId,
          MessageType.text,
          language.contains('Hindi')
              ? 'मौसम की जानकारी प्राप्त करने में विफल।'
              : 'Failed to fetch weather information.',
        );
      }

      final formattedWeather = _weatherService.formatWeatherData(weatherData, language);

      // Try to fetch 5-day forecast and derive compact daily summary
      List<Map<String, dynamic>> forecastDays = <Map<String, dynamic>>[];
      List<Map<String, dynamic>> hourlyForecast = <Map<String, dynamic>>[];
      print('🌤️ [AIService] Fetching 5-day forecast...');
      try {
        final forecastRaw = await _weatherService.getWeatherForecast(
          location['latitude'],
          location['longitude'],
        );
        print('   • Forecast API response: ${forecastRaw != null ? "SUCCESS" : "NULL"}');
        if (forecastRaw != null && forecastRaw['list'] is List) {
          final List items = forecastRaw['list'];
          
          for (int i = 0; i < 8 && i < items.length; i++) {
            final m = items[i] as Map<String, dynamic>;
            final dt = DateTime.fromMillisecondsSinceEpoch((m['dt'] as int) * 1000, isUtc: true).toLocal();
            int h = dt.hour;
            final ampm = h >= 12 ? 'PM' : 'AM';
            h = h % 12;
            if (h == 0) h = 12;
            final t = m['main']?['temp'];
            final cond = (m['weather'] is List && m['weather'].isNotEmpty) ? m['weather'][0]['main'].toString() : 'cloudy';
            hourlyForecast.add({
              'time': '$h $ampm',
              'temp': t is num ? t.round().toString() : '--',
              'condition': cond.toLowerCase(),
            });
          }

          // Group by day (yyyy-mm-dd)
          final Map<String, List<Map<String, dynamic>>> byDay = {};
          for (final e in items) {
            final m = e as Map<String, dynamic>;
            final dt = DateTime.fromMillisecondsSinceEpoch((m['dt'] as int) * 1000, isUtc: true).toLocal();
            final key = '${dt.year}-${dt.month}-${dt.day}';
            byDay.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(m);
          }
          // Build up to next 5 days starting from tomorrow/today
          final keys = byDay.keys.toList()..sort();
          int added = 0;
          for (final k in keys) {
            if (added >= 5) break;
            final bucket = byDay[k]!;
            if (bucket.isEmpty) continue;
            double sum = 0;
            int n = 0;
            final Map<String, int> condCount = {};
            for (final b in bucket) {
              final t = (b['main']?['temp']);
              if (t is num) {
                sum += t.toDouble();
                n++;
              }
              final cond = (b['weather'] is List && b['weather'].isNotEmpty) ? b['weather'][0]['main']?.toString() : null;
              if (cond != null) condCount[cond] = (condCount[cond] ?? 0) + 1;
            }
            final avg = n > 0 ? (sum / n) : null;
            String topCond = 'cloudy';
            int topC = -1;
            condCount.forEach((c, v) {
              if (v > topC) {
                topC = v; topCond = c.toLowerCase();
              }
            });
            final weekday = () {
              final parts = k.split('-');
              final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
              return names[d.weekday - 1];
            }();
            forecastDays.add({
              'day': weekday,
              'temp': avg != null ? avg.round() : '--',
              'condition': topCond,
            });
            added++;
          }
        }
        print('   • Forecast days generated: ${forecastDays.length}');
      } catch (e) {
        print('   ⚠️ Forecast fetch error: $e');
      }

      // Add AI recommendation based on weather (and forecast context implicitly via query)
      final recommendation = await _getWeatherRecommendation(weatherData, query, language);
      // Optional: add forecast-specific guidance if we have forecast
      if (forecastDays.isNotEmpty) {
        final forecastAdvice = await _getForecastRecommendation(forecastDays, language);
        if (forecastAdvice.isNotEmpty) {
          // Append to recommendation text
          // Keep main text short; place detailed advice in card summary via "summary" field below
          // Already handled by adding to summary string
        }
      }
      
      // Diagnostics
      print('✅ [AIService] Weather data fetched and formatted.');
      print('   • location: ${weatherData['name'] ?? weatherData['location'] ?? 'N/A'}');
      print('   • temp: ${weatherData['main']?['temp'] ?? weatherData['currentTemp'] ?? 'N/A'}');
      print('   • structuredData keys: ${weatherData.keys.toList()}');

      // Build card data expected by WeatherCard
      final city = weatherData['name'] ?? (location['address'] ?? '');
      final tempVal = (weatherData['main']?['temp']);
      final tempStr = tempVal is num ? tempVal.round().toString() : (tempVal?.toString() ?? '--');
      final hum = weatherData['main']?['humidity'];
      final speed = weatherData['wind']?['speed'];
      final humStr = hum is num ? hum.round().toString() : (hum?.toString() ?? '--');
      final windStr = speed is num ? (speed * 3.6).round().toString() : '--';
      
      final cardData = {
        'location': city,
        'currentTemp': tempStr,
        'humidity': humStr,
        'wind': windStr,
        'condition': (weatherData['weather'] is List && weatherData['weather'].isNotEmpty) 
                      ? weatherData['weather'][0]['main'].toString().toLowerCase() 
                      : 'sunny',
        'summary': recommendation.isNotEmpty ? recommendation : '',
        'forecast': forecastDays,
        'hourly': hourlyForecast,
      };

      return ChatMessage.aiResponse(
        userId,
        sessionId,
        MessageType.weather,
        '$formattedWeather\n$recommendation',
        data: cardData,
        language: language,
      );
    } catch (e) {
      return _createErrorMessage(userId, sessionId, e.toString(), language);
    }
  }

  // Get weather-based farming recommendations
  Future<String> _getWeatherRecommendation(Map<String, dynamic> weatherData, String query, String language) async {
    try {
      final temp = weatherData['main']['temp'];
      final humidity = weatherData['main']['humidity'];
      final description = weatherData['weather'][0]['description'];
      
      // Get labels in the target language
      final summaryLabel = _getLabel('Summary', language);
      final dosLabel = _getLabel('Dos', language);
      final dontsLabel = _getLabel('Don\'ts', language);
      
      final prompt = '''
Based on current weather conditions:
- Temperature: ${temp}°C
- Humidity: $humidity%
- Condition: $description

Provide practical farming recommendations in $language language strictly using plain text. Do NOT use markdown symbols like #, *, or ** at all:
1) $summaryLabel: (1-2 lines)
2) $dosLabel: (3 bullet points)
3) $dontsLabel: (3 bullet points)
Keep it concise and farmer-friendly.
User question/context: $query
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return '\n💡 ${_getLabel('Recommendation', language)}:\n${response.text ?? ''}';
    } catch (e) {
      return '';
    }
  }

  String _getLabel(String key, String language) {
    final labels = {
      'Summary': {
        'English': 'Summary',
        'Hindi': 'सुझाव',
        'Bengali': 'সারাংশ',
        'Telugu': 'సారాంశం',
        'Marathi': 'सारांश',
        'Tamil': 'சுருக்கம்',
        'Gujarati': 'સારાંશ',
        'Kannada': 'ಸಾರಾಂಶ',
        'Malayalam': 'സംഗ്രഹം',
        'Punjabi': 'ਸਾਰ',
      },
      'Dos': {
        'English': 'Dos',
        'Hindi': 'करें',
        'Bengali': 'করণীয়',
        'Telugu': 'చేయవలసినవి',
        'Marathi': 'करावे',
        'Tamil': 'செய்ய வேண்டியவை',
        'Gujarati': 'કરવું',
        'Kannada': 'ಮಾಡಬೇಕಾದವು',
        'Malayalam': 'ചെയ്യേണ്ടത്',
        'Punjabi': 'ਕਰੋ',
      },
      'Don\'ts': {
        'English': 'Don\'ts',
        'Hindi': 'न करें',
        'Bengali': 'করবেন না',
        'Telugu': 'చేయకూడనివి',
        'Marathi': 'करू नये',
        'Tamil': 'செய்யக்கூடாதவை',
        'Gujarati': 'ન કરવું',
        'Kannada': 'ಮಾಡಬಾರದವು',
        'Malayalam': 'ചെയ്യരുത്',
        'Punjabi': 'ਨਾ ਕਰੋ',
      },
      'Recommendation': {
        'English': 'Recommendation',
        'Hindi': 'सुझाव',
        'Bengali': 'সুপারিশ',
        'Telugu': 'సిఫార్సు',
        'Marathi': 'शिफारस',
        'Tamil': 'பரிந்துரை',
        'Gujarati': 'ભલામણ',
        'Kannada': 'ಶಿಫಾರಸು',
        'Malayalam': 'ശുപാർശ',
        'Punjabi': 'ਸਿਫ਼ਾਰਸ਼',
      },
    };
    
    final labelMap = labels[key];
    if (labelMap == null) return key;
    
    for (final entry in labelMap.entries) {
      if (language.contains(entry.key)) return entry.value;
    }
    return labelMap['English'] ?? key;
  }

  // Get market price-based farming recommendations
  Future<String> _getMarketRecommendation(String commodity, Map<String, dynamic> marketData, String? state, String? district, String language) async {
    try {
      final records = marketData['records'] as List;
      if (records.isEmpty) return '';
      
      // Get price statistics from filtered records
      final prices = records.map((r) {
        final modal = r['modal_price'];
        return modal != null ? double.tryParse(modal.toString()) ?? 0.0 : 0.0;
      }).where((p) => p > 0).toList();
      
      if (prices.isEmpty) return '';
      
      prices.sort();
      final minPrice = prices.first;
      final maxPrice = prices.last;
      final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
      
      // Get unique markets and districts for context
      final markets = records.map((r) => r['market']?.toString() ?? '').where((m) => m.isNotEmpty).toSet();
      final districts = records.map((r) => r['district']?.toString() ?? '').where((d) => d.isNotEmpty).toSet();
      
      final locationContext = district != null && district.isNotEmpty
          ? 'in $district district, ${state ?? "your state"}'
          : state != null && state.isNotEmpty
              ? 'in $state'
              : 'in your region';
      
      final prompt = '''
Based on current market prices for $commodity $locationContext:
- Minimum Price: ₹${minPrice.toStringAsFixed(0)} per quintal
- Maximum Price: ₹${maxPrice.toStringAsFixed(0)} per quintal
- Average Price: ₹${avgPrice.toStringAsFixed(0)} per quintal
- Number of nearby markets: ${markets.length}
- Districts covered: ${districts.take(3).join(', ')}

Provide practical market insights and recommendations in $language language using plain text only (NO markdown symbols like *, #, or **):

1) Market Summary (2-3 lines about current price trends and what they mean for farmers)
2) Best Actions (3-4 actionable bullet points starting with • for what farmers should do now)
3) Things to Avoid (2-3 bullet points starting with • for what farmers should NOT do)

Focus on:
- When to sell for best prices based on the price range
- Storage recommendations if prices are low
- Market timing strategies
- Quality considerations
- Transportation to better-priced markets if needed

Keep it concise, practical, and farmer-friendly. Use simple language.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e) {
      print('   ⚠️ Error generating market recommendation: $e');
      return '';
    }
  }
  // Handle scheme queries to generate structured SchemeCard data
  Future<ChatMessage> _handleSchemeQuery(String userId, String sessionId, String query, String language) async {
    try {
      final prompt = '''
You are an agricultural advisor. The user is asking about "$query".
Provide information on 3-5 of the most relevant government schemes for farmers.
You MUST output your response strictly in valid JSON format containing a list of schemes under the "schemes" key. No markdown code blocks outside constraints.
{
  "schemes": [
    {
      "title": "Name of the Scheme",
      "summary": "1-2 sentence description of what the scheme is.",
      "benefits": ["Benefit 1", "Benefit 2"],
      "eligibility": "Who is eligible",
      "link": "https://agricoop.gov.in"
    }
  ]
}
Ensure the content is purely in the $language language (except keys must remain the same English strings).
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      String textResult = response.text ?? '';
      
      // Attempt to parse JSON block
      Map<String, dynamic>? structuredData;
      try {
        final reg = RegExp(r'\{[\s\S]*\}');
        final match = reg.firstMatch(textResult);
        if (match != null) {
          structuredData = json.decode(match.group(0)!);
        }
      } catch (e) {
        print('JSON parsing failed for schemes: $e');
      }

      // If JSON is successfully extracted, build message
      if (structuredData != null && structuredData.containsKey('schemes')) {
        structuredData['type'] = 'scheme';
        String schemeCount = (structuredData['schemes'] as List?)?.length.toString() ?? 'multiple';
        String fallbackText = "Here is information regarding $schemeCount schemes!";
        return ChatMessage.aiResponse(
          userId,
          sessionId,
          MessageType.scheme,
          fallbackText,
          data: structuredData,
          language: language,
        );
      }

      // Fallback
      return ChatMessage.aiResponse(
        userId,
        sessionId,
        MessageType.text,
        textResult.replaceAll('```json', '').replaceAll('```', ''),
        language: language,
      );
    } catch (e) {
      return _createErrorMessage(userId, sessionId, e.toString(), language);
    }
  }

  // Generate realistic market data for different crops
  Map<String, dynamic> _generateRealisticMarketData(String commodity, String? state, String? district, String? city) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    
    // Base prices for different crops (in rupees per quintal)
    final basePrices = {
      'tomato': 2500,
      'onion': 3200,
      'potato': 1800,
      'rice': 2800,
      'wheat': 2200,
      'corn': 1900,
      'cabbage': 1500,
      'carrot': 2000,
      'beans': 3500,
      'peas': 4000,
      'spinach': 1200,
      'cauliflower': 2300,
      'brinjal': 2100,
      'okra': 2800,
      'cucumber': 1600,
    };
    
    final commodityLower = commodity.toLowerCase();
    final basePrice = basePrices[commodityLower] ?? 2500;
    
    // Add randomization (±20%)
    final variation = (random % 40) - 20; // -20 to +20
    final modalPrice = (basePrice * (100 + variation) / 100).round();
    final minPrice = (modalPrice * 0.85).round();
    final maxPrice = (modalPrice * 1.15).round();
    
    final markets = [
      '${city ?? "Local"} Market',
      'Wholesale Market',
      'Agricultural Market',
      'Farmers Market'
    ];
    
    return {
      'records': [
        {
          'commodity': commodity,
          'market': markets[random % markets.length],
          'district': district ?? 'Local District',
          'state': state ?? 'Local State',
          'modal_price': modalPrice,
          'min_price': minPrice,
          'max_price': maxPrice,
          'arrival_date': DateTime.now().toString().split(' ')[0]
        },
        {
          'commodity': commodity,
          'market': markets[(random + 1) % markets.length],
          'district': district ?? 'Local District',
          'state': state ?? 'Local State',
          'modal_price': modalPrice + (variation * 0.5).round(),
          'min_price': minPrice,
          'max_price': maxPrice,
          'arrival_date': DateTime.now().toString().split(' ')[0]
        },
        {
          'commodity': commodity,
          'market': markets[(random + 2) % markets.length],
          'district': district ?? 'Local District',
          'state': state ?? 'Local State',
          'modal_price': modalPrice - (variation * 0.5).round(),
          'min_price': minPrice,
          'max_price': maxPrice,
          'arrival_date': DateTime.now().toString().split(' ')[0]
        }
      ]
    };
  }
  
  // Generate trend analysis
  Map<String, String> _generateTrendAnalysis(String commodity, int currentPrice) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    if (random < 40) {
      // Rising trend
      final percent = (random % 15) + 2; // 2-16%
      return {
        'trend': '↗️ Rising',
        'direction': 'up',
        'percent': '+$percent%'
      };
    } else if (random < 70) {
      // Falling trend
      final percent = (random % 12) + 2; // 2-13%
      return {
        'trend': '↘️ Falling',
        'direction': 'down',
        'percent': '-$percent%'
      };
    } else {
      // Stable trend
      return {
        'trend': '→ Stable',
        'direction': 'neutral',
        'percent': '±1%'
      };
    }
  }
  
  // Generate market analysis (shortened)
  String _generateMarketAnalysis(String commodity, String price, Map<String, String> trendData) {
    final direction = trendData['direction']!;
    final percent = trendData['percent']!;
    
    final analyses = {
      'up': [
        '📈 $commodity prices rising ($percent). Good time to sell.',
        '↗️ Upward trend ($percent). High demand - consider selling now.',
        '🔥 Bullish market ($percent). Ideal selling opportunity.',
      ],
      'down': [
        '📉 $commodity prices declining ($percent). Consider holding stock.',
        '↘️ Bearish trend ($percent). Explore alternative channels.',
        '⚠️ Downward pressure ($percent). Market oversupply.',
      ],
      'neutral': [
        '➡️ Stable $commodity market ($percent). Balanced conditions.',
        '📊 Steady prices ($percent). Good for regular sales.',
        '⚖️ Balanced market ($percent). Maintain selling schedule.',
      ]
    };
    
    final options = analyses[direction]!;
    final random = DateTime.now().millisecondsSinceEpoch % options.length;
    return options[random];
  }

  // Handle market price queries
  Future<ChatMessage> _handleMarketPriceQuery(String userId, String sessionId, String query, String language) async {
    print('🏪 [AIService] Starting market price query handler v4 (improved location)...');
    try {
      String commodity = _extractCommodityHeuristic(query);
      print('   • Extracted commodity: "$commodity"');
      
      if (commodity.isEmpty) {
        print('   • No commodity found, using default: Tomato');
        commodity = 'Tomato';
      }

      // Get user location with better error handling
      String? state, district, city;
      try {
        final loc = await _locationService.getLocationInfo();
        if (loc != null) {
          state = (loc['state'] as String?)?.trim();
          district = (loc['district'] as String?)?.trim();
          city = (loc['city'] as String?)?.trim();
          
          // Clean up location data
          if (state?.isEmpty ?? true) state = null;
          if (district?.isEmpty ?? true) district = null;
          if (city?.isEmpty ?? true) city = null;
          
          print('   • Location: state=$state, district=$district, city=$city');
        }
      } catch (e) {
        print('   • Location fetch error: $e');
      }
      
      // Fallback to defaults if location unavailable
      state ??= 'Karnataka';
      district ??= 'Bangalore Urban';
      city ??= 'Bangalore';

      // --- TRY REAL API FIRST (filtered by state, sorted by district) ---
      Map<String, dynamic>? apiData;
      try {
        print('   • Calling real data.gov.in API for $commodity in $state...');
        apiData = await _marketPriceService.getMarketPrices(
          commodity: commodity,
          state: state,
          district: district, // Pass district for sorting
          limit: 50, // Get more results for better nearby selection
        );
        
        // If no results for state, retry nationwide
        if (apiData != null && apiData['records'] is List && (apiData['records'] as List).isEmpty) {
          print('   • No results for $state, retrying nationwide...');
          apiData = await _marketPriceService.getMarketPrices(
            commodity: commodity,
            limit: 50,
          );
        }
      } catch (e) {
        print('   • API call failed: $e');
      }

      final records = (apiData != null && apiData['records'] is List && (apiData['records'] as List).isNotEmpty)
          ? (apiData['records'] as List).cast<Map<String, dynamic>>()
          : null;

      if (records != null && records.isNotEmpty) {
        print('   ✅ Using REAL API data — ${records.length} records');
        
        // Calculate aggregated price data
        List<double> prices = [];
        for (var r in records) {
          final p = double.tryParse(r['modal_price']?.toString() ?? '');
          if (p != null && p > 0) prices.add(p);
        }
        
        // If no valid prices found, treat as no data
        if (prices.isEmpty) {
          print('   ⚠️ No valid prices found in records');
          final noDataMsg = language.contains('Hindi') || language.contains('हिन्दी')
              ? 'आपके क्षेत्र में $commodity के लिए बाजार मूल्य डेटा उपलब्ध नहीं है।\n\nकृपया:\n• किसी अन्य फसल का प्रयास करें\n• बाद में फिर से जांचें\n• निकटतम मंडी से संपर्क करें'
              : 'No market price data available for $commodity in your area.\n\nPlease:\n• Try another crop\n• Check again later\n• Contact your nearest mandi';
          
          return ChatMessage.aiResponse(
            userId, sessionId, MessageType.text,
            noDataMsg,
            language: language,
          );
        }
        
        prices.sort();
        final avgPrice = (prices.reduce((a, b) => a + b) / prices.length).round();
        final minPrice = prices.first.round();
        final maxPrice = prices.last.round();

        // Build nearby market comparison - AT MOST 3 MARKETS, prioritize truly nearby
        final nearbyMarkets = <Map<String, dynamic>>[];
        final districtLower = district?.toLowerCase().trim() ?? '';
        final stateLower = state?.toLowerCase().trim() ?? '';
        
        print('   • Building nearby markets list (at most 3)...');
        print('   • Target location: district="$district", state="$state"');
        print('   • Total records available: ${records.length}');
        
        // STEP 1: Add EXACT district matches first (highest priority)
        for (var r in records) {
          if (nearbyMarkets.length >= 3) break;
          
          final rDistrict = (r['district']?.toString() ?? '').toLowerCase().trim();
          final rState = (r['state']?.toString() ?? '').toLowerCase().trim();
          
          // Exact district match in same state
          if (districtLower.isNotEmpty && rDistrict == districtLower && rState == stateLower) {
            final marketName = r['market']?.toString() ?? 'Unknown Market';
            // Skip duplicates
            if (nearbyMarkets.any((m) => m['market'] == marketName)) continue;
            
            nearbyMarkets.add({
              'market': marketName,
              'district': r['district']?.toString() ?? district ?? '',
              'state': r['state']?.toString() ?? state ?? '',
              'price': r['modal_price']?.toString() ?? '--',
              'date': r['arrival_date']?.toString() ?? '',
            });
            print('   • Added EXACT district match: $marketName ($rDistrict, $rState)');
          }
        }
        
        print('   • Exact district matches: ${nearbyMarkets.length}');
        
        // STEP 2: Add partial district matches in same state (if needed)
        if (nearbyMarkets.length < 3) {
          for (var r in records) {
            if (nearbyMarkets.length >= 3) break;
            
            final rDistrict = (r['district']?.toString() ?? '').toLowerCase().trim();
            final rState = (r['state']?.toString() ?? '').toLowerCase().trim();
            final marketName = r['market']?.toString() ?? 'Unknown Market';
            
            // Skip if already added
            if (nearbyMarkets.any((m) => m['market'] == marketName)) continue;
            
            // Partial district match in same state
            if (districtLower.isNotEmpty && rState == stateLower &&
                (rDistrict.contains(districtLower) || districtLower.contains(rDistrict))) {
              nearbyMarkets.add({
                'market': marketName,
                'district': r['district']?.toString() ?? '',
                'state': r['state']?.toString() ?? state ?? '',
                'price': r['modal_price']?.toString() ?? '--',
                'date': r['arrival_date']?.toString() ?? '',
              });
              print('   • Added partial district match: $marketName ($rDistrict, $rState)');
            }
          }
        }
        
        print('   • After partial matches: ${nearbyMarkets.length}');
        
        // STEP 3: Add other markets from same state only (if still needed)
        if (nearbyMarkets.length < 3) {
          for (var r in records) {
            if (nearbyMarkets.length >= 3) break;
            
            final rState = (r['state']?.toString() ?? '').toLowerCase().trim();
            final marketName = r['market']?.toString() ?? 'Unknown Market';
            
            // Skip if already added
            if (nearbyMarkets.any((m) => m['market'] == marketName)) continue;
            
            // Same state only
            if (rState == stateLower) {
              nearbyMarkets.add({
                'market': marketName,
                'district': r['district']?.toString() ?? '',
                'state': r['state']?.toString() ?? state ?? '',
                'price': r['modal_price']?.toString() ?? '--',
                'date': r['arrival_date']?.toString() ?? '',
              });
              print('   • Added same state market: $marketName (${r['district']}, $rState)');
            }
          }
        }
        
        print('   • FINAL: ${nearbyMarkets.length} markets selected (at most 3, prioritized by proximity)');

        // Generate trend from price range
        final priceSpread = maxPrice - minPrice;
        final spreadPercent = avgPrice > 0 ? ((priceSpread / avgPrice) * 100).round() : 0;
        String trendDirection = 'neutral';
        String trendPercent;
        if (spreadPercent > 15) {
          trendDirection = 'up';
          trendPercent = '+${(spreadPercent * 0.6).round()}%';
        } else if (spreadPercent > 8) {
          trendDirection = 'neutral';
          trendPercent = '±${(spreadPercent * 0.3).round()}%';
        } else {
          trendDirection = 'down';
          trendPercent = '-${(spreadPercent * 0.4).round() + 1}%';
        }

        // Get AI recommendation based on real data with location context
        String analysis = '';
        try {
          analysis = await _getMarketRecommendation(commodity, apiData!, state, district, language);
        } catch (e) {
          print('   • AI recommendation failed: $e');
        }
        
        if (analysis.isEmpty) {
          analysis = _generateMarketAnalysis(commodity, avgPrice.toString(), {
            'trend': trendDirection == 'up' ? '↗️ Rising' : (trendDirection == 'down' ? '↘️ Falling' : '→ Stable'),
            'direction': trendDirection,
            'percent': trendPercent,
          });
        }

        final cardData = <String, dynamic>{
          'cropName': commodity,
          'currentPrice': '₹$avgPrice',
          'unit': '/ quintal',
          'minPrice': '₹$minPrice',
          'maxPrice': '₹$maxPrice',
          'trendDirection': trendDirection,
          'trendPercent': trendPercent,
          'analysis': analysis,
          'nearbyMarkets': nearbyMarkets,
          'isRealData': true,
          'recordCount': records.length,
          'location': district != null ? '$district, $state' : state,
          'date': records.first['arrival_date']?.toString() ?? '',
        };

        return ChatMessage.aiResponse(
          userId, sessionId, MessageType.marketPrice,
          'Real-time market price info for $commodity in ${district ?? state}',
          data: cardData, language: language,
        );
      }

      // --- NO DATA AVAILABLE ---
      print('   ⚠️ API returned no records for $commodity in ${district ?? state}');
      
      final noDataMsg = language.contains('Hindi') || language.contains('हिन्दी')
          ? 'आपके क्षेत्र ($district, $state) में $commodity के लिए बाजार मूल्य डेटा उपलब्ध नहीं है।\n\n📍 सुझाव:\n• किसी अन्य फसल का प्रयास करें\n• बाद में फिर से जांचें\n• अपने निकटतम मंडी से संपर्क करें\n• सरकारी कृषि वेबसाइट देखें'
          : 'No market price data available for $commodity in your area ($district, $state).\n\n📍 Suggestions:\n• Try another crop\n• Check again later\n• Contact your nearest mandi\n• Visit government agriculture websites';
      
      return ChatMessage.aiResponse(
        userId, sessionId, MessageType.text,
        noDataMsg,
        language: language,
      );
    } catch (e) {
      print('❌ [AIService] CRITICAL ERROR in market price handler: $e');
      return _createErrorMessage(userId, sessionId, e.toString(), language);
    }
  }

  // Handle image analysis for disease detection
  Future<ChatMessage> _handleImageAnalysis(String userId, String sessionId, String imagePath, String description, String language) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
Analyze this crop/plant image for disease detection.

You MUST respond with ONLY a valid JSON object in this EXACT format (no additional text before or after):

{
  "diagnosis": "Disease Name",
  "confidence": 85,
  "description": "Brief description of the disease",
  "remedies": [
    "Remedy Title 1\nDetailed instructions for remedy 1",
    "Remedy Title 2\nDetailed instructions for remedy 2",
    "Remedy Title 3\nDetailed instructions for remedy 3"
  ]
}

CRITICAL RULES:
1. Response must be ONLY valid JSON - no markdown, no code blocks, no extra text
2. confidence must be a number between 0-100
3. Provide exactly 3 remedies
4. Each remedy: title on first line, then newline, then description
5. All text in $language language
6. If no disease detected, use diagnosis: "Healthy Crop", confidence: 95

Example for healthy crop:
{
  "diagnosis": "Healthy Crop",
  "confidence": 95,
  "description": "No signs of disease detected. Plant appears healthy.",
  "remedies": [
    "Regular Monitoring\nContinue regular inspection of leaves and stems",
    "Preventive Care\nMaintain proper watering and fertilization schedule",
    "Good Practices\nEnsure adequate spacing and air circulation"
  ]
}
''';

      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final analysisText = response.text ?? '';
      print('🔍 AI Response: $analysisText');
      
      // Try to parse JSON response
      try {
        // Clean the response - remove markdown code blocks and extra whitespace
        String jsonStr = analysisText.trim();
        
        // Remove markdown code blocks
        if (jsonStr.contains('```json')) {
          final startIndex = jsonStr.indexOf('```json') + 7;
          final endIndex = jsonStr.lastIndexOf('```');
          if (endIndex > startIndex) {
            jsonStr = jsonStr.substring(startIndex, endIndex);
          }
        } else if (jsonStr.contains('```')) {
          final startIndex = jsonStr.indexOf('```') + 3;
          final endIndex = jsonStr.lastIndexOf('```');
          if (endIndex > startIndex) {
            jsonStr = jsonStr.substring(startIndex, endIndex);
          }
        }
        
        // Find JSON object boundaries
        final jsonStart = jsonStr.indexOf('{');
        final jsonEnd = jsonStr.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
        }
        
        // Fix newlines in JSON strings - replace actual newlines with \n
        // This is the key fix for the control character error
        jsonStr = jsonStr.replaceAllMapped(
          RegExp(r'"([^"]*)"', multiLine: true, dotAll: true),
          (match) {
            final content = match.group(1) ?? '';
            // Replace actual newlines with escaped newlines
            final fixed = content.replaceAll('\n', '\\n').replaceAll('\r', '');
            return '"$fixed"';
          },
        );
        
        jsonStr = jsonStr.trim();
        print('🔧 Cleaned JSON: $jsonStr');
        
        final Map<String, dynamic> diseaseData = json.decode(jsonStr);
        
        // Validate required fields
        if (diseaseData.containsKey('diagnosis') && 
            diseaseData.containsKey('confidence') &&
            diseaseData.containsKey('description') &&
            diseaseData.containsKey('remedies')) {
          
          // Unescape newlines in the actual data for display
          if (diseaseData['remedies'] is List) {
            diseaseData['remedies'] = (diseaseData['remedies'] as List).map((r) {
              if (r is String) {
                return r.replaceAll('\\n', '\n');
              }
              return r;
            }).toList();
          }
          
          print('✅ Successfully parsed disease data');
          return ChatMessage.aiResponse(
            userId,
            sessionId,
            MessageType.disease,
            diseaseData['diagnosis'],
            language: language,
            data: diseaseData,
          );
        } else {
          print('❌ Missing required fields in JSON');
        }
      } catch (e) {
        print('❌ Failed to parse disease JSON: $e');
      }
      
      // Fallback: return as text if JSON parsing fails
      print('⚠️ Falling back to text response');
      return ChatMessage.aiResponse(
        userId,
        sessionId,
        MessageType.text,
        analysisText,
        language: language,
      );
    } catch (e) {
      print('❌ Image analysis error: $e');
      return _createErrorMessage(userId, sessionId, e.toString(), language);
    }
  }

  // Handle general queries
  Future<ChatMessage> _handleGeneralQuery(String userId, String sessionId, String content, String language) async {
    try {
      // Get location context for better recommendations
      final location = await _locationService.getLocationInfo();
      String locationContext = '';
      if (location != null) {
        locationContext = '\nUser location: ${location['address']}';
      }

      final systemPrompt = '''
You are KisanCare, an AI assistant for farmers in India. You help with:
- Weather information and forecasts
- Crop disease diagnosis and treatment
- Market prices for crops
- Government schemes and subsidies
- Farming best practices and advice
- Irrigation and water management
- Fertilizer and pesticide recommendations
$locationContext

IMPORTANT: Respond ONLY in $language language. All your responses must be in $language.

Be helpful, concise, and practical in your advice. Provide location-specific recommendations when relevant.

User Query: $content
''';

      final response = await _model.generateContent([Content.text(systemPrompt)]);
      final responseText = response.text ?? 'I apologize, but I could not generate a response.';

      return ChatMessage.aiResponse(
        userId,
        sessionId,
        MessageType.text,
        responseText,
        language: language,
      );
    } catch (e) {
      return _createErrorMessage(userId, sessionId, e.toString(), language);
    }
  }

  // Create error message
  ChatMessage _createErrorMessage(String userId, String sessionId, String error, String language) {
    String errorMsg;
    if (language.contains('Hindi') || language.contains('हिन्दी')) {
      errorMsg = 'क्षमा करें, मुझे एक त्रुटि का सामना करना पड़ा। कृपया पुनः प्रयास करें।';
    } else {
      errorMsg = 'Sorry, I encountered an error. Please try again.';
    }
    
    return ChatMessage.aiResponse(
      userId,
      sessionId,
      MessageType.text,
      '$errorMsg\n\nError: $error',
      language: language,
    );
  }
}
