import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../models/message_model.dart';
import '../../widgets/scheme_card.dart';
import '../../config/app_theme.dart';
import '../../utils/translations.dart';

class SchemesPage extends StatefulWidget {
  final String sessionId;
  final String language;

  const SchemesPage({Key? key, required this.sessionId, required this.language}) : super(key: key);

  @override
  _SchemesPageState createState() => _SchemesPageState();
}

class _SchemesPageState extends State<SchemesPage> {
  final AIService _aiService = AIService();
  final LocationService _locationService = LocationService();
  ChatMessage? _schemesData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchemes();
  }

  Future<void> _fetchSchemes() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    // Get user location for area-based schemes
    String locationInfo = '';
    try {
      final loc = await _locationService.getLocationInfo();
      if (loc != null) {
        final state = loc['state'] ?? '';
        final district = loc['district'] ?? '';
        if (state.toString().isNotEmpty) {
          locationInfo = ' in $state${district.toString().isNotEmpty ? ", $district" : ""}';
        }
      }
    } catch (_) {}

    final response = await _aiService.sendQuery(
      userId: userId,
      sessionId: widget.sessionId,
      queryType: 'text',
      content: 'what are the latest government schemes for farmers$locationInfo',
      language: widget.language,
    );

    if (mounted) {
      setState(() {
        _schemesData = response;
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.tr('Government Schemes', widget.language), style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: () {
              setState(() { _isLoading = true; });
              _fetchSchemes();
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_schemesData?.structuredData != null && _schemesData!.structuredData!['schemes'] != null)
                 ...(_schemesData!.structuredData!['schemes'] as List).map((s) => Padding(
                   padding: const EdgeInsets.only(bottom: 16.0),
                   child: SchemeCard(data: s),
                 )).toList()
              else
                 Container(
                   padding: const EdgeInsets.all(24),
                   decoration: BoxDecoration(color: AppTheme.aiBubbleGrey, borderRadius: BorderRadius.circular(32)),
                   child: Text(_schemesData?.textContent ?? Translations.tr('No schemes loaded.', widget.language), style: Theme.of(context).textTheme.bodyLarge),
                 )
            ],
        ),
    );
  }
}
