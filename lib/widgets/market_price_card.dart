import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../utils/translations.dart';

class MarketPriceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? language;

  const MarketPriceCard({super.key, required this.data, this.language});

  @override
  Widget build(BuildContext context) {
    final cropName = (data['cropName'] ?? 'Unknown Crop').toString();
    final currentPrice = (data['currentPrice'] ?? '--').toString();
    final unit = (data['unit'] ?? '/ quintal').toString();
    final trendDirection = (data['trendDirection'] ?? 'neutral').toString();
    final trendPercent = (data['trendPercent'] ?? '').toString();
    final analysis = (data['analysis'] ?? '').toString();
    final nearbyMarkets = (data['nearbyMarkets'] as List?) ?? [];
    final isRealData = data['isRealData'] == true;

    Color trendColor = trendDirection == 'up'
        ? const Color(0xFF2E7D32)
        : trendDirection == 'down'
            ? const Color(0xFFD32F2F)
            : const Color(0xFF9E9E9E);

    Color trendBg = trendDirection == 'up'
        ? const Color(0xFFE8F5E9)
        : trendDirection == 'down'
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFF5F5F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Insight Banner
        if (analysis.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    Translations.tr('Market Insight', language ?? 'English').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  analysis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Price Trends Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Price Trends',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (isRealData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Price Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop name + trend badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cropName,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  if (trendPercent.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: trendBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trendPercent,
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currentPrice,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mini bar chart visual
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildMiniBarChart(trendDirection),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nearby Market Comparison
        if (nearbyMarkets.isNotEmpty) ...[
          const Text(
            'Nearby Market Comparison',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...nearbyMarkets.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value as Map<String, dynamic>;
            final marketName = m['market']?.toString() ?? 'Unknown';
            final district = m['district']?.toString() ?? '';
            final price = m['price']?.toString() ?? '--';
            
            // Better labels for 3 markets
            String label;
            Color iconColor;
            if (i == 0) {
              label = 'MARKET\n#1';
              iconColor = const Color(0xFF2E7D32);
            } else if (i == 1) {
              label = 'MARKET\n#2';
              iconColor = const Color(0xFF5C6BC0);
            } else {
              label = 'MARKET\n#3';
              iconColor = const Color(0xFFFF9800);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          marketName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          district,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹$price',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        label,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  List<Widget> _buildMiniBarChart(String trend) {
    // Generate a simple 5-bar visual trend chart
    List<double> heights;
    List<Color> colors;

    if (trend == 'up') {
      heights = [0.4, 0.5, 0.55, 0.7, 0.9];
      colors = List.filled(5, const Color(0xFF2E7D32));
    } else if (trend == 'down') {
      heights = [0.8, 0.7, 0.6, 0.5, 0.35];
      colors = List.filled(5, const Color(0xFFD32F2F));
    } else {
      heights = [0.5, 0.6, 0.55, 0.65, 0.6];
      colors = List.filled(5, const Color(0xFF9E9E9E));
    }

    return List.generate(5, (index) {
      return Container(
        width: 28,
        height: 50 * heights[index],
        decoration: BoxDecoration(
          color: colors[index].withAlpha(index < 3 ? 100 : 200),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    });
  }
}
