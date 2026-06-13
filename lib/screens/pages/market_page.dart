import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../models/message_model.dart';
import '../../widgets/market_price_card.dart';
import '../../config/app_theme.dart';
import '../../utils/translations.dart';

class MarketPage extends StatefulWidget {
  final String sessionId;
  final String language;

  const MarketPage({Key? key, required this.sessionId, required this.language}) : super(key: key);

  @override
  _MarketPageState createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final AIService _aiService = AIService();
  ChatMessage? _selectedCropData;
  bool _isLoading = false;
  String? _selectedCrop;

  static const List<Map<String, dynamic>> _crops = [
    {'name': 'Tomato', 'icon': '🍅', 'color': Color(0xFFFF6B6B)},
    {'name': 'Potato', 'icon': '🥔', 'color': Color(0xFFD4A373)},
    {'name': 'Onion', 'icon': '🧅', 'color': Color(0xFFE8A87C)},
    {'name': 'Wheat', 'icon': '🌾', 'color': Color(0xFFD4A373)},
    {'name': 'Rice', 'icon': '🌱', 'color': Color(0xFF8BC34A)},
    {'name': 'Cotton', 'icon': '🤍', 'color': Color(0xFFBDBDBD)},
    {'name': 'Soybean', 'icon': '🫘', 'color': Color(0xFF8B9D77)},
    {'name': 'Maize', 'icon': '🌽', 'color': Color(0xFFF4D35E)},
    {'name': 'Chilli', 'icon': '🌶️', 'color': Color(0xFFFF4444)},
    {'name': 'Sugarcane', 'icon': '🎋', 'color': Color(0xFF7BC67E)},
    {'name': 'Banana', 'icon': '🍌', 'color': Color(0xFFFFE135)},
    {'name': 'Turmeric', 'icon': '🟡', 'color': Color(0xFFFFA000)},
    {'name': 'Groundnut', 'icon': '🥜', 'color': Color(0xFFD4A373)},
    {'name': 'Mustard', 'icon': '🟨', 'color': Color(0xFFFFD700)},
    {'name': 'Gram', 'icon': '🫛', 'color': Color(0xFFA8C68F)},
    {'name': 'Coriander', 'icon': '🌿', 'color': Color(0xFF4CAF50)},
  ];

  Future<void> _fetchCropPrice(String cropName) async {
    setState(() { _isLoading = true; _selectedCrop = cropName; });
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    final response = await _aiService.sendQuery(
      userId: userId,
      sessionId: widget.sessionId,
      queryType: 'text',
      content: 'what is the market price of $cropName',
      language: widget.language,
    );

    if (mounted) {
      setState(() {
        _selectedCropData = response;
        _isLoading = false;
      });
    }
  }

  void _goBack() {
    setState(() {
      _selectedCrop = null;
      _selectedCropData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _selectedCrop != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
        title: Text(
          _selectedCrop != null
              ? Translations.tr(_selectedCrop!, widget.language)
              : Translations.tr('Market Insights', widget.language),
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
      ),
      body: _selectedCrop != null ? _buildDetailView() : _buildCropSelector(),
    );
  }

  Widget _buildCropSelector() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          Translations.tr('Check Market Prices', widget.language),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          Translations.tr('Select a crop to view real-time prices near you', widget.language),
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 28),

        // Crop Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _crops.length,
          itemBuilder: (context, index) {
            final crop = _crops[index];
            return _buildCropTile(crop);
          },
        ),
      ],
    );
  }

  Widget _buildCropTile(Map<String, dynamic> crop) {
    return GestureDetector(
      onTap: () => _fetchCropPrice(crop['name']),
      child: Container(
        decoration: BoxDecoration(
          color: (crop['color'] as Color).withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (crop['color'] as Color).withAlpha(80), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(crop['icon'], style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              Translations.tr(crop['name'], widget.language),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(height: 20),
            Text(
              'Fetching live prices for $_selectedCrop...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_selectedCropData?.structuredData != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MarketPriceCard(
            data: _selectedCropData!.structuredData!,
            language: widget.language,
          ),
          const SizedBox(height: 24),
          // Back to crops button
          Center(
            child: TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.grid_view_rounded, color: AppTheme.primaryGreen),
              label: Text(
                Translations.tr('View all crops', widget.language),
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedCropData?.textContent ?? Translations.tr('No data found', widget.language),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _goBack,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: Text(Translations.tr('View all crops', widget.language), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
