import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../models/message_model.dart';
import '../../widgets/disease_card.dart';
import '../../config/app_theme.dart';
import '../../utils/translations.dart';

class DiseasePage extends StatefulWidget {
  final String sessionId;
  final String language;

  const DiseasePage({Key? key, required this.sessionId, required this.language}) : super(key: key);

  @override
  _DiseasePageState createState() => _DiseasePageState();
}

class _DiseasePageState extends State<DiseasePage> {
  final AIService _aiService = AIService();
  ChatMessage? _diseaseData;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  String? _currentImagePath;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId == null) return;

      setState(() {
        _isLoading = true;
        _currentImagePath = null;
        _diseaseData = null;
      });

      // Save locally
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'crop_disease_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${directory.path}/$fileName';
      await File(image.path).copy(localPath);

      setState(() {
        _currentImagePath = localPath;
      });

      final response = await _aiService.sendQuery(
        userId: userId,
        sessionId: widget.sessionId,
        queryType: 'image',
        content: 'Analyze this crop image for diseases or issues',
        imagePath: localPath,
        language: widget.language,
      );

      if (mounted) {
        setState(() {
          _diseaseData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              title: Text(Translations.tr('Camera', widget.language)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: Text(Translations.tr('Gallery', widget.language)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.tr('Crop Disease Detection', widget.language), style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_currentImagePath == null)
              Container(
                 padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
                 width: double.infinity,
                 decoration: BoxDecoration(color: AppTheme.aiBubbleGrey, borderRadius: BorderRadius.circular(32)),
                 child: Column(
                   children: [
                     Icon(Icons.energy_savings_leaf, size: 64, color: AppTheme.primaryGreen),
                     SizedBox(height: 16),
                     Text(Translations.tr('Upload a photo of your affected crop leaf to diagnose the issue immediately.', widget.language), 
                       textAlign: TextAlign.center,
                       style: Theme.of(context).textTheme.bodyLarge),
                     SizedBox(height: 24),
                     ElevatedButton.icon(
                       icon: Icon(Icons.upload_file),
                       label: Text(Translations.tr('Upload Image', widget.language)),
                       onPressed: _showImageSourceDialog,
                     )
                   ],
                 ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.file(File(_currentImagePath!), height: 250, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                     const Padding(
                       padding: EdgeInsets.all(32.0),
                       child: CircularProgressIndicator(),
                     )
                  else if (_diseaseData != null)
                     if (_diseaseData!.structuredData != null)
                       DiseaseCard(
                         data: _diseaseData!.structuredData!,
                         imageUrl: _currentImagePath,
                       )
                     else if (_diseaseData!.textContent != null && _diseaseData!.textContent!.isNotEmpty)
                       Container(
                         padding: const EdgeInsets.all(24),
                         width: double.infinity,
                         decoration: BoxDecoration(color: AppTheme.aiBubbleGrey, borderRadius: BorderRadius.circular(32)),
                         child: Text(_diseaseData!.textContent!, style: Theme.of(context).textTheme.bodyLarge)
                       ),
                  if (!_isLoading && _diseaseData != null)
                    const SizedBox(height: 16),
                  if (!_isLoading && _diseaseData != null)
                    OutlinedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: Icon(Icons.refresh, color: AppTheme.primaryGreen),
                      label: Text(Translations.tr('Scan Another', widget.language), style: TextStyle(color: AppTheme.textDark)),
                      style: OutlinedButton.styleFrom(
                         side: BorderSide(color: AppTheme.borderColor),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
                      )
                    )
                ],
              )
          ],
        ),
      ),
    );
  }
}
