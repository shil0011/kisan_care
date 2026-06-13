import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';

class SchemeCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const SchemeCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Government Scheme';
    final summary = data['summary'] ?? 'No information available';
    final benefits = data['benefits'] as List<dynamic>? ?? [];
    final eligibility = data['eligibility'] as String?;
    final link = data['link'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.account_balance, size: 32, color: AppTheme.infoBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Government Scheme',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scheme Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.infoBlue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Summary
            Text(
              summary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),

            // Benefits
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, size: 20, color: AppTheme.accentYellow),
                  const SizedBox(width: 8),
                  Text(
                    'Key Benefits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...benefits.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppTheme.successGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Eligibility
            if (eligibility != null && eligibility.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.how_to_reg, size: 20, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Eligibility',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                eligibility,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
              ),
            ],

            // Learn More Button
            if (link != null && link.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final Uri url = Uri.parse(link);
                      print('🔗 Attempting to launch URL: $link');
                      
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        // Try with platformDefault mode if externalApplication fails
                        if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
                          throw Exception('Could not launch $link');
                        }
                      }
                      print('✅ URL launched successfully');
                    } catch (e) {
                      print('❌ Error launching URL: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open link. Error: $e'),
                            backgroundColor: AppTheme.warningRed,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Learn More'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.infoBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
