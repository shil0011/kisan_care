import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/message_model.dart';
import 'weather_card.dart';
import 'market_price_card.dart';
import 'disease_card.dart';
import 'scheme_card.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeakTap;
  final bool isSpeaking;

  const MessageBubble({
    super.key,
    required this.message,
    this.onSpeakTap,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserMessage(context);
    } else {
      return _buildAIMessage(context);
    }
  }

  Widget _buildUserMessage(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 64, right: 12, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.userBubbleBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImageWidget(message.imageUrl!),
              ),
              if (message.textContent != null && message.textContent!.isNotEmpty)
                const SizedBox(height: 8),
            ],
            if (message.textContent != null && message.textContent!.isNotEmpty)
              Text(
                message.textContent!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIMessage(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rich Cards for structured data (WITH voice button)
          if (message.structuredData != null) ...[
            Stack(
              children: [
                _buildRichCard(context),
                if (onSpeakTap != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)
                        ]
                      ),
                      padding: const EdgeInsets.all(4),
                      child: InkWell(
                        onTap: onSpeakTap,
                        child: Icon(
                          isSpeaking ? Icons.stop_circle : Icons.volume_up,
                          color: isSpeaking ? AppTheme.warningRed : AppTheme.primaryGreen,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Simple text bubble (WITH voice button)
            Container(
              margin: const EdgeInsets.only(right: 64, left: 12, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.aiBubbleGrey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      message.textContent ?? 'No response',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (onSpeakTap != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onSpeakTap,
                      child: Icon(
                        isSpeaking ? Icons.stop_circle : Icons.volume_up,
                        color: isSpeaking ? AppTheme.warningRed : AppTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichCard(BuildContext context) {
    switch (message.type) {
      case MessageType.weather:
        return WeatherCard(data: message.structuredData!, language: message.language);
      case MessageType.marketPrice:
        return MarketPriceCard(data: message.structuredData!, language: message.language);
      case MessageType.disease:
        return DiseaseCard(
          data: message.structuredData!,
          imageUrl: message.imageUrl,
        );
      case MessageType.scheme:
        final schemesList = message.structuredData?['schemes'] as List?;
        if (schemesList != null && schemesList.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: schemesList.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SchemeCard(data: s),
            )).toList(),
          );
        }
        return SchemeCard(data: message.structuredData!);
      default:
        return Container(
          margin: const EdgeInsets.only(right: 64, left: 12, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.aiBubbleGrey,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  message.textContent ?? 'No response',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (onSpeakTap != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onSpeakTap,
                  child: Icon(
                    isSpeaking ? Icons.stop_circle : Icons.volume_up,
                    color: isSpeaking ? AppTheme.warningRed : AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  // Helper method to display both local and network images
  Widget _buildImageWidget(String imagePath) {
    // Check if it's a local file path or network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: 200,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      // Local file
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        );
      } else {
        return Container(
          width: 200,
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 50),
        );
      }
    }
  }
}
