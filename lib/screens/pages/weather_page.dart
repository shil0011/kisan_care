import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../models/message_model.dart';
import '../../widgets/weather_card.dart';
import '../../config/app_theme.dart';
import '../../utils/translations.dart';

class WeatherPage extends StatefulWidget {
  final String sessionId;
  final String language;

  const WeatherPage({Key? key, required this.sessionId, required this.language}) : super(key: key);

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final AIService _aiService = AIService();
  ChatMessage? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    final response = await _aiService.sendQuery(
      userId: userId,
      sessionId: widget.sessionId,
      queryType: 'text',
      content: 'get detailed weather forecast',
      language: widget.language,
    );

    if (mounted) {
      setState(() {
        _weatherData = response;
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.tr('Weather Dashboard', widget.language), style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: () {
              setState(() { _isLoading = true; });
              _fetchWeather();
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_weatherData?.structuredData != null)
                 WeatherCard(data: _weatherData!.structuredData!, language: widget.language)
              else
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(color: AppTheme.aiBubbleGrey, borderRadius: BorderRadius.circular(32)),
                   child: Text(_weatherData?.textContent ?? Translations.tr('Error fetching weather data', widget.language), style: Theme.of(context).textTheme.bodyLarge),
                 )
            ],
        ),
    );
  }
}
