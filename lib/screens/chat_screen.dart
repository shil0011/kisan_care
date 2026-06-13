import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_theme.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/chat_session_service.dart';
import '../models/chat_session_model.dart';
import '../widgets/message_bubble.dart';
import 'auth_screen.dart';
import '../test_apis_screen.dart';
import '../utils/translations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AIService _aiService = AIService();
  final ChatSessionService _sessionService = ChatSessionService();
  
  bool _isLoading = false;
  bool _isListening = false;
  bool _isTtsEnabled = true;
  bool _isSpeaking = false;
  String? _speakingMessageId; // Track which message is being spoken
  String _userLanguage = 'English';
  ChatSession? _currentSession;
  Stream<List<ChatMessage>>? _chatStream;
  String? _selectedImagePath; // Store selected image before sending
  bool _hasInitialScrolled = false; // Track if we've done initial scroll

  List<String> get _suggestionChips => [
    Translations.tr("Today's Weather", _userLanguage),
    Translations.tr("Tomato Market Price", _userLanguage),
    Translations.tr("Check my crop", _userLanguage),
    Translations.tr("Government Schemes", _userLanguage),
  ];

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
    // Initialize session and language in background without blocking UI
    _initializeInBackground();
  }

  Future<void> _initializeInBackground() async {
    try {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId != null) {
        // Load language preference quickly
        final profile = await _firestoreService.getUserProfile(userId);
        if (profile != null && profile['language'] != null && mounted) {
          setState(() {
            _userLanguage = profile['language'] as String;
          });
        }
        
        // Fetch or create session to fix infinite loading circle
        final sessions = await _sessionService.getUserSessions(userId).first;
        if (mounted) {
          ChatSession activeSession;
          if (sessions.isNotEmpty) {
             activeSession = sessions.first;
          } else {
             activeSession = await _sessionService.createNewSession(userId);
          }
          setState(() { 
            _currentSession = activeSession;
            _chatStream = _firestoreService.getChatHistory(activeSession.id);
          });
          
          // Scroll to bottom ONLY on initial load (once)
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted && _scrollController.hasClients && !_hasInitialScrolled) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              _hasInitialScrolled = true;
            }
          });
        }
      }
    } catch (e) {
      print('Background initialization error: $e');
      // Continue with defaults if initialization fails
    }
  }

  Future<void> _ensureSession() async {
    if (_currentSession == null) {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId != null) {
        _currentSession = await _sessionService.createNewSession(userId);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // _audioRecorder.dispose();  // Temporarily disabled
    super.dispose();
  }

  void _scrollToBottom() {
    // Helper method for manual scrolling (not used during interactions)
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final hasImage = _selectedImagePath != null;
    
    // Allow sending if there's either text or an image
    if (message.isEmpty && !hasImage) return;

    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure we have a session
      await _ensureSession();

      // Handle image message
      if (hasImage) {
        final imagePath = _selectedImagePath!;
        final textContent = message.isNotEmpty ? message : 'Analyze this crop image for diseases or issues';
        
        // Create user message with image
        final userMessage = ChatMessage.userImage(userId, _currentSession!.id, imagePath);
        await _firestoreService.saveMessage(userMessage);
        
        // Clear input and selected image
        _messageController.clear();
        setState(() {
          _selectedImagePath = null;
        });
        // Don't scroll after sending

        // Get AI response for image analysis
        final aiResponse = await _aiService.sendQuery(
          userId: userId,
          sessionId: _currentSession!.id,
          queryType: 'image',
          content: textContent,
          imagePath: imagePath,
          language: _userLanguage,
        );

        // Update session with new message
        await _sessionService.updateSessionOnNewMessage(_currentSession!.id, 'Image uploaded');

        // Save AI response
        await _firestoreService.saveMessage(aiResponse);
        // Don't scroll after AI response
      } else {
        // Handle text message
        final userMessage = ChatMessage.userText(userId, _currentSession!.id, message);
        await _firestoreService.saveMessage(userMessage);
        _messageController.clear();
        // Don't scroll after sending

        // Update session with new message
        await _sessionService.updateSessionOnNewMessage(_currentSession!.id, message);

        // Get AI response
        final aiResponse = await _aiService.sendQuery(
          userId: userId,
          sessionId: _currentSession!.id,
          queryType: 'text',
          content: message,
          language: _userLanguage,
        );

        // Save AI response
        await _firestoreService.saveMessage(aiResponse);
        // Don't scroll after AI response
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId == null) return;

      // Store image locally - copy to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${directory.path}/$fileName';
      await File(image.path).copy(localPath);

      // Ensure we have a session
      if (_currentSession == null) {
        final newSession = await _sessionService.createNewSession(userId);
        setState(() {
          _currentSession = newSession;
          _chatStream = _firestoreService.getChatHistory(newSession.id);
        });
      }

      // Store the selected image path but DON'T send yet
      setState(() {
        _selectedImagePath = localPath;
      });

      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 Image selected. Add a description or press send.'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.warningRed),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isListening) {
      // Stop listening
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    } else {
      // Request microphone permission first
      final micPermission = await Permission.microphone.request();
      
      if (!micPermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission is required for voice input'),
              backgroundColor: AppTheme.warningRed,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Start listening
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (error) {
          print('Speech error: ${error.errorMsg}');
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice input error: ${error.errorMsg}'),
                backgroundColor: AppTheme.warningRed,
              ),
            );
          }
        },
      );

      if (available) {
        if (mounted) {
          setState(() => _isListening = true);
        }
        
        // Determine locale based on user language
        String localeId = 'en_US';
        if (_userLanguage.contains('Hindi') || _userLanguage.contains('हिन्दी')) {
          localeId = 'hi_IN';
        } else if (_userLanguage.contains('Tamil')) {
          localeId = 'ta_IN';
        } else if (_userLanguage.contains('Telugu')) {
          localeId = 'te_IN';
        } else if (_userLanguage.contains('Bengali')) {
          localeId = 'bn_IN';
        } else if (_userLanguage.contains('Marathi')) {
          localeId = 'mr_IN';
        } else if (_userLanguage.contains('Gujarati')) {
          localeId = 'gu_IN';
        } else if (_userLanguage.contains('Kannada')) {
          localeId = 'kn_IN';
        } else if (_userLanguage.contains('Malayalam')) {
          localeId = 'ml_IN';
        } else if (_userLanguage.contains('Punjabi')) {
          localeId = 'pa_IN';
        }
        
        await _speechToText.listen(
          onResult: (result) {
            // Update text without triggering full rebuild
            _messageController.text = result.recognizedWords;
          },
          localeId: localeId,
          listenMode: stt.ListenMode.confirmation,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device'),
              backgroundColor: AppTheme.warningRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-IN'); // Default to English (India)
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakMessage(String text, String messageId) async {
    if (!_isTtsEnabled) return;
    
    // If already speaking this message, stop it
    if (_isSpeaking && _speakingMessageId == messageId) {
      await _flutterTts.stop();
      // Update state without rebuilding entire list
      _isSpeaking = false;
      _speakingMessageId = null;
      // Force update only the voice button, not the whole list
      setState(() {});
      return;
    }
    
    // If speaking a different message, stop that and start this one
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    
    try {
      // Update state without rebuilding entire list
      _isSpeaking = true;
      _speakingMessageId = messageId;
      setState(() {}); // Minimal rebuild
      
      // Set language based on user preference
      String ttsLanguage = 'en-IN'; // Default
      if (_userLanguage.contains('English')) {
        ttsLanguage = 'en-IN';
      } else if (_userLanguage.contains('Hindi') || _userLanguage.contains('हिन्दी')) {
        ttsLanguage = 'hi-IN';
      } else if (_userLanguage.contains('Tamil') || _userLanguage.contains('தமிழ்')) {
        ttsLanguage = 'ta-IN';
      } else if (_userLanguage.contains('Telugu') || _userLanguage.contains('తెలుగు')) {
        ttsLanguage = 'te-IN';
      } else if (_userLanguage.contains('Bengali') || _userLanguage.contains('বাংলা')) {
        ttsLanguage = 'bn-IN';
      } else if (_userLanguage.contains('Marathi') || _userLanguage.contains('मराठी')) {
        ttsLanguage = 'mr-IN';
      } else if (_userLanguage.contains('Gujarati') || _userLanguage.contains('ગુજરાતી')) {
        ttsLanguage = 'gu-IN';
      } else if (_userLanguage.contains('Kannada') || _userLanguage.contains('ಕನ್ನಡ')) {
        ttsLanguage = 'kn-IN';
      } else if (_userLanguage.contains('Malayalam') || _userLanguage.contains('മലയാളം')) {
        ttsLanguage = 'ml-IN';
      } else if (_userLanguage.contains('Punjabi') || _userLanguage.contains('ਪੰਜਾਬੀ')) {
        ttsLanguage = 'pa-IN';
      }
      
      await _flutterTts.setLanguage(ttsLanguage);
      
      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          _isSpeaking = false;
          _speakingMessageId = null;
          setState(() {}); // Minimal rebuild
        }
      });
      
      // Clean text for better speech (remove emojis and special formatting)
      String cleanText = text
          .replaceAll(RegExp(r'[\u{1f300}-\u{1f5ff}\u{1f900}-\u{1f9ff}\u{1f600}-\u{1f64f}\u{1f680}-\u{1f6ff}\u{2600}-\u{26ff}\u{2700}-\u{27bf}]', unicode: true), '')
          .replaceAll('•', '')
          .replaceAll('**', '')
          .replaceAll('##', '')
          .replaceAll('###', '')
          .replaceAll('₹', 'Rupees ')
          .replaceAll('°C', ' degrees Celsius')
          .replaceAll('%', ' percent')
          .trim();
      
      if (cleanText.isNotEmpty) {
        await _flutterTts.speak(cleanText);
        
        // DON'T show snackbar to avoid distraction
      }
    } catch (e) {
      _isSpeaking = false;
      _speakingMessageId = null;
      setState(() {}); // Minimal rebuild
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Could not speak message'),
            backgroundColor: AppTheme.warningRed,
          ),
        );
      }
    }
  }

  // Generate voice summary for structured data
  String _generateVoiceSummary(ChatMessage message) {
    if (message.structuredData == null) {
      return message.textContent ?? '';
    }

    final data = message.structuredData!;
    
    switch (message.type) {
      case MessageType.weather:
        final location = data['location'] ?? 'your area';
        final temp = data['currentTemp'] ?? '--';
        final condition = data['condition'] ?? 'clear';
        final humidity = data['humidity'] ?? '--';
        final wind = data['wind'] ?? '--';
        final summary = data['summary'] ?? '';
        
        return '${Translations.tr("Weather update for", _userLanguage)} $location. ${Translations.tr("Current temperature is", _userLanguage)} $temp ${Translations.tr("degrees Celsius", _userLanguage)}. ${Translations.tr("Conditions are", _userLanguage)} $condition. ${Translations.tr("Humidity is", _userLanguage)} $humidity ${Translations.tr("percent", _userLanguage)}. ${Translations.tr("Wind speed is", _userLanguage)} $wind ${Translations.tr("kilometers per hour", _userLanguage)}. $summary';
        
      case MessageType.marketPrice:
        final crop = data['cropName'] ?? 'crop';
        final price = (data['currentPrice'] ?? '--').toString().replaceAll('₹', '');
        final minPrice = (data['minPrice'] ?? '--').toString().replaceAll('₹', '');
        final maxPrice = (data['maxPrice'] ?? '--').toString().replaceAll('₹', '');
        final location = data['location'] ?? 'your area';
        final markets = (data['nearbyMarkets'] as List?) ?? [];
        final analysis = data['analysis'] ?? '';
        
        String summary = '${Translations.tr("Market price update for", _userLanguage)} $crop ${Translations.tr("in", _userLanguage)} $location. ${Translations.tr("Average price is", _userLanguage)} ${Translations.tr("Rupees", _userLanguage)} $price ${Translations.tr("per quintal", _userLanguage)}. ${Translations.tr("Prices range from", _userLanguage)} ${Translations.tr("Rupees", _userLanguage)} $minPrice ${Translations.tr("to", _userLanguage)} ${Translations.tr("Rupees", _userLanguage)} $maxPrice. ';
        
        if (markets.isNotEmpty) {
          summary += '${Translations.tr("Nearby markets", _userLanguage)}: ';
          for (int i = 0; i < markets.length && i < 3; i++) {
            final market = markets[i] as Map<String, dynamic>;
            final name = market['market'] ?? 'Unknown';
            final mPrice = (market['price'] ?? '--').toString();
            summary += '$name ${Translations.tr("at", _userLanguage)} ${Translations.tr("Rupees", _userLanguage)} $mPrice. ';
          }
        }
        
        summary += analysis;
        return summary;
        
      case MessageType.disease:
        // Generate comprehensive voice summary for disease detection
        final diagnosis = data['diagnosis'] ?? 'Unknown Disease';
        final confidence = data['confidence'] ?? 0;
        final description = data['description'] ?? '';
        final remedies = (data['remedies'] as List?) ?? [];
        
        String summary = '${Translations.tr("Crop disease detection results", _userLanguage)}. ${Translations.tr("Diagnosis", _userLanguage)}: $diagnosis. ${Translations.tr("Confidence level", _userLanguage)}: ${confidence.toStringAsFixed(0)} ${Translations.tr("percent", _userLanguage)}. ';
        
        if (description.isNotEmpty) {
          summary += '${Translations.tr("Description", _userLanguage)}: $description. ';
        }
        
        if (remedies.isNotEmpty) {
          summary += '${Translations.tr("Recommended remedies", _userLanguage)}: ';
          for (int i = 0; i < remedies.length; i++) {
            summary += '${Translations.tr("Remedy", _userLanguage)} ${i + 1}: ${remedies[i]}. ';
          }
        }
        
        return summary;
        
      case MessageType.scheme:
        final schemes = (data['schemes'] as List?) ?? [];
        if (schemes.isEmpty) {
          return message.textContent ?? Translations.tr('Government schemes information', _userLanguage);
        }
        
        String summary = '${Translations.tr("Here are", _userLanguage)} ${schemes.length} ${Translations.tr("government schemes for farmers", _userLanguage)}. ';
        for (int i = 0; i < schemes.length && i < 3; i++) {
          final scheme = schemes[i] as Map<String, dynamic>;
          final title = scheme['title'] ?? 'Scheme';
          final desc = scheme['summary'] ?? '';
          summary += '$title. $desc. ';
        }
        return summary;
        
      default:
        return message.textContent ?? '';
    }
  }

  Future<void> _changeLanguage(String newLanguage) async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId != null) {
      try {
        // Update language in Firestore
        await _firestoreService.updateUserProfile(userId, {'language': newLanguage});
        
        // Update local state
        setState(() {
          _userLanguage = newLanguage;
        });
        
        // Update TTS language
        await _updateTtsLanguage(newLanguage);
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌐 Language changed to $newLanguage'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            backgroundColor: AppTheme.warningRed,
          ),
        );
      }
    }
  }

  Future<void> _updateTtsLanguage(String language) async {
    String ttsLanguage = 'en-IN'; // Default
    
    if (language.contains('Hindi') || language.contains('हिन्दी')) {
      ttsLanguage = 'hi-IN';
    } else if (language.contains('Tamil') || language.contains('தமிழ்')) {
      ttsLanguage = 'ta-IN';
    } else if (language.contains('Telugu') || language.contains('తెలుగు')) {
      ttsLanguage = 'te-IN';
    } else if (language.contains('Bengali') || language.contains('বাংলা')) {
      ttsLanguage = 'bn-IN';
    } else if (language.contains('Marathi') || language.contains('मराठी')) {
      ttsLanguage = 'mr-IN';
    } else if (language.contains('Gujarati') || language.contains('ગુજરાતી')) {
      ttsLanguage = 'gu-IN';
    } else if (language.contains('Kannada') || language.contains('ಕನ್ನಡ')) {
      ttsLanguage = 'kn-IN';
    } else if (language.contains('Malayalam') || language.contains('മലയാളം')) {
      ttsLanguage = 'ml-IN';
    } else if (language.contains('Punjabi') || language.contains('ਪੰਜਾਬੀ')) {
      ttsLanguage = 'pa-IN';
    }
    
    await _flutterTts.setLanguage(ttsLanguage);
  }

  Future<void> _startNewChat() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId != null) {
      try {
        // Check if current session is empty (no messages)
        if (_currentSession != null) {
          final currentSessionMessages = await _firestoreService.getChatHistory(_currentSession!.id).first;
          
          // If current session has no messages, don't create new session
          if (currentSessionMessages.isEmpty) {
            setState(() {
              _messageController.clear();
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('💬 Already in empty chat'),
                backgroundColor: AppTheme.primaryGreen,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        }
        
        // Create a new chat session only if current one has messages
        final newSession = await _sessionService.createNewSession(userId);
        
        setState(() {
          _currentSession = newSession;
          _chatStream = _firestoreService.getChatHistory(newSession.id);
          _messageController.clear();
          _hasInitialScrolled = false; // Reset flag for new chat
        });
        
        // Scroll to bottom for new chat
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _scrollController.hasClients && !_hasInitialScrolled) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            _hasInitialScrolled = true;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🆕 New chat started'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating new chat: $e'),
            backgroundColor: AppTheme.warningRed,
          ),
        );
      }
    }
  }

  Widget _buildChatHistoryDrawer() {
    final userId = context.read<AuthService>().currentUser?.uid;
    
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 100,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.accentYellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chat Sessions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // New Chat Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close drawer
                  _startNewChat();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          
          const Divider(),
          
          // Chat History List
          Expanded(
            child: userId == null
                ? const Center(
                    child: Text('Please sign in to view chat history'),
                  )
                : StreamBuilder<List<ChatSession>>(
                    stream: _sessionService.getUserSessions(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final sessions = snapshot.data ?? [];

                      if (sessions.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: AppTheme.textLight,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No chat sessions yet',
                                  style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start a conversation to see your chat sessions here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final isCurrentSession = _currentSession?.id == session.id;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrentSession ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrentSession ? Border.all(color: AppTheme.primaryGreen, width: 1) : null,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCurrentSession ? AppTheme.primaryGreen : AppTheme.textLight,
                                radius: 16,
                                child: Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrentSession ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrentSession ? AppTheme.primaryGreen : null,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    _formatTime(session.lastMessageAt),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  if (session.messageCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.textLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${session.messageCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isCurrentSession ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ) : null,
                              onTap: () {
                                Navigator.pop(context); // Close drawer
                                _switchToSession(session);
                              },
                              onLongPress: () {
                                _showSessionOptions(session);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _switchToSession(ChatSession session) {
    setState(() {
      _currentSession = session;
      _chatStream = _firestoreService.getChatHistory(session.id);
      _hasInitialScrolled = false; // Reset flag to allow scroll for new session
    });
    
    // Scroll to bottom when switching sessions
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _scrollController.hasClients && !_hasInitialScrolled) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _hasInitialScrolled = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to: ${session.title}'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSessionOptions(ChatSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename Session'),
              onTap: () {
                Navigator.pop(context);
                _renameSession(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.warningRed),
              title: const Text('Delete Session', style: TextStyle(color: AppTheme.warningRed)),
              onTap: () {
                Navigator.pop(context);
                _deleteSession(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameSession(ChatSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                await _sessionService.updateSessionTitle(session.id, newTitle);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteSession(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _sessionService.deleteSession(session.id);
              if (_currentSession?.id == session.id) {
                // If we deleted the current session, create a new one
                final userId = context.read<AuthService>().currentUser?.uid;
                if (userId != null) {
                  final newSession = await _sessionService.createNewSession(userId);
                  setState(() {
                    _currentSession = newSession;
                    _chatStream = _firestoreService.getChatHistory(newSession.id);
                  });
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.warningRed)),
          ),
        ],
      ),
    );
  }

  String _getLanguageCode(String language) {
    if (language.contains('English')) return 'EN';
    if (language.contains('Hindi') || language.contains('हिन्दी')) return 'HI';
    if (language.contains('Tamil') || language.contains('தமிழ்')) return 'TA';
    if (language.contains('Telugu') || language.contains('తెలుగు')) return 'TE';
    if (language.contains('Bengali') || language.contains('বাংলা')) return 'BN';
    if (language.contains('Marathi') || language.contains('मराठी')) return 'MR';
    if (language.contains('Gujarati') || language.contains('ગુજરાતી')) return 'GU';
    if (language.contains('Kannada') || language.contains('ಕನ್ನಡ')) return 'KN';
    if (language.contains('Malayalam') || language.contains('മലയാളം')) return 'ML';
    if (language.contains('Punjabi') || language.contains('ਪੰਜਾਬੀ')) return 'PA';
    return 'EN'; // Default
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _signOut() async {
    try {
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final userId = context.read<AuthService>().currentUser?.uid;

    return Scaffold(
      drawer: _buildChatHistoryDrawer(),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('KisanCare', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: const [
          SizedBox(width: 48), // space for global user icon overlay
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: userId == null
                ? const Center(child: Text('Please sign in'))
                : _currentSession == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _chatStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          final messages = snapshot.data ?? [];

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Start a conversation',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ask me about weather, prices, or crop health',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          // No auto-scroll in ListView builder - only on initial load in initState

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: messages.length,
                            addAutomaticKeepAlives: true, // Keep list items alive to prevent rebuilds
                            cacheExtent: 1000, // Cache more items to reduce rebuilds
                            physics: const ClampingScrollPhysics(), // Prevent bounce that triggers rebuilds
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              // Debug: log message type and presence of structured data
                              // ignore: avoid_print
                              print('[ChatScreen] message ${message.id} | isUser=${message.isUser} | type=${message.type} | hasStructuredData=${message.structuredData != null}');
                              if (!message.isUser && message.structuredData != null) {
                                final keys = message.structuredData!.keys.toList();
                                print('  • structuredData keys: $keys');
                                if (message.type == MessageType.weather) {
                                  print('  • weather.location=${message.structuredData!['location'] ?? message.structuredData!['name']}');
                                  print('  • weather.currentTemp=${message.structuredData!['currentTemp'] ?? message.structuredData!['main']?['temp']}');
                                } else if (message.type == MessageType.marketPrice) {
                                  print('  • market.cropName=${message.structuredData!['cropName']}');
                                  print('  • market.currentPrice=${message.structuredData!['currentPrice']}');
                                }
                              }
                              return MessageBubble(
                                key: ValueKey(message.id), // Add key to prevent rebuilds
                                message: message,
                                isSpeaking: _isSpeaking && _speakingMessageId == message.id,
                                onSpeakTap: !message.isUser
                                    ? () => _speakMessage(_generateVoiceSummary(message), message.id)
                                    : null,
                              );
                            },
                          );
                        },
                      ),
          ),

          // Suggestion Chips
          if (!_isLoading)
            Container(
              height: 56, // Slightly taller for reachability
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestionChips.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ActionChip(
                      label: Text(_suggestionChips[index]),
                      onPressed: () {
                        _messageController.text = _suggestionChips[index];
                        _sendMessage();
                      },
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  );
                },
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Processing...'),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground, // Background Color Shift Instead of Border!
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textSecondary.withOpacity(0.06), // Ambient shadow
                  blurRadius: 32,
                  offset: const Offset(0, -12),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Preview (if image selected)
                if (_selectedImagePath != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        // Image thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImagePath!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Image info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📷 Image selected',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add description or press send',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Remove button
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppTheme.warningRed,
                          onPressed: () {
                            setState(() {
                              _selectedImagePath = null;
                            });
                          },
                          tooltip: 'Remove image',
                        ),
                      ],
                    ),
                  ),
                
                // Input row
                Row(
                  children: [
                    // Camera Button
                    IconButton(
                      icon: const Icon(Icons.camera_alt, size: 28),
                      color: AppTheme.primaryGreen,
                      onPressed: _isLoading ? null : _showImageSourceDialog,
                      tooltip: 'Upload image',
                    ),

                    // Text Input
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type Here...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isLoading,
                        onSubmitted: (text) => _sendMessage(),
                      ),
                    ),

                    // Microphone Button
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 28,
                      ),
                      color: _isListening ? AppTheme.warningRed : AppTheme.primaryGreen,
                      onPressed: _isLoading ? null : _toggleRecording,
                      tooltip: _isListening ? 'Stop listening' : 'Voice input',
                    ),

                    // Send Button
                    IconButton(
                      icon: const Icon(Icons.send, size: 28),
                      color: AppTheme.accentOrange,
                      onPressed: _isLoading
                          ? null
                          : () => _sendMessage(),
                      tooltip: 'Send message',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
