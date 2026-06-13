import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';

class DiseaseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? imageUrl;

  const DiseaseCard({super.key, required this.data, this.imageUrl});

  void _shareResults(BuildContext context) {
    final diagnosis = data['diagnosis'] ?? 'Unknown Disease';
    final confidence = data['confidence'] ?? 0;
    final description = data['description'] ?? 'No description available';
    final remedies = data['remedies'] as List<dynamic>? ?? [];
    
    String shareText = '🌾 KisanCare Crop Disease Detection\n\n';
    shareText += '🔍 Diagnosis: $diagnosis\n';
    shareText += '✅ Confidence: ${confidence.toStringAsFixed(0)}%\n\n';
    shareText += '📝 Description:\n$description\n\n';
    
    if (remedies.isNotEmpty) {
      shareText += '💊 Recommended Remedies:\n';
      for (int i = 0; i < remedies.length; i++) {
        shareText += '${i + 1}. ${remedies[i]}\n';
      }
    }
    
    Share.share(shareText, subject: 'Crop Disease Detection Results');
  }

  @override
  Widget build(BuildContext context) {
    final diagnosis = data['diagnosis'] ?? 'Unknown Disease';
    final confidence = data['confidence'] ?? 0;
    final description = data['description'] ?? 'No description available';
    final remedies = data['remedies'] as List<dynamic>? ?? [];

    final confidenceColor = confidence >= 90
        ? AppTheme.successGreen
        : confidence >= 70
            ? AppTheme.accentYellow
            : AppTheme.warningRed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidence Badge
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: confidenceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(0)}% CERTAIN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Diagnosis
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bug_report, color: AppTheme.warningRed, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diagnosis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Remedies
            if (remedies.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...remedies.asMap().entries.map((entry) {
                final icons = [Icons.cut, Icons.water_drop, Icons.grass];
                final colors = [AppTheme.warningRed, Colors.blue, AppTheme.successGreen];
                final index = entry.key % icons.length;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors[index].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors[index],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icons[index], size: 20, color: colors[index]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.toString().split('\n').first,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            if (entry.value.toString().contains('\n'))
                              Text(
                                entry.value.toString().split('\n').skip(1).join('\n'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // Share Button
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _shareResults(context),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share Results'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
