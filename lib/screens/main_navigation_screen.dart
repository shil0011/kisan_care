import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/chat_session_service.dart';
import '../models/chat_session_model.dart';
import '../models/user_preferences.dart';
import '../utils/translations.dart';
import 'auth_screen.dart';

// Screens
import 'chat_screen.dart';
import 'pages/weather_page.dart';
import 'pages/market_page.dart';
import 'pages/disease_page.dart';
import 'pages/schemes_page.dart';

import '../services/ai_service.dart';
import '../models/message_model.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String _userLanguage = 'English';
  String _userName = '';
  String _userEmail = '';
  ChatSession? _currentSession;
  final ChatSessionService _sessionService = ChatSessionService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  // Voice assistant
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId != null) {
        final profile = await _firestoreService.getUserProfile(userId);
        if (profile != null) {
          if (profile['language'] != null) _userLanguage = profile['language'];
          _userName = profile['name'] ?? '';
          _userEmail = profile['email'] ?? '';
        }

        final sessionsStream = _sessionService.getUserSessions(userId);
        final sessions = await sessionsStream.first;
        if (sessions.isNotEmpty) {
           List<ChatSession> valid = sessions.cast<ChatSession>();
           _currentSession = valid.first;
        } else {
           _currentSession = await _sessionService.createNewSession(userId);
        }
      }
    } catch (e) {
      print('Navigation init error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _changeLanguage(String newLanguage) async {
    setState(() { _userLanguage = newLanguage; });
    try {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId != null) {
        await _firestoreService.updateUserProfile(userId, {'language': newLanguage});
      }
    } catch (_) {}
  }

  void _showUserProfile() {
    final user = context.read<AuthService>().currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildProfileSheet(user),
    );
  }

  Widget _buildProfileSheet(dynamic user) {
    final initials = _userName.isNotEmpty
        ? _userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),

          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _userName.isNotEmpty ? _userName : 'Farmer',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail.isNotEmpty ? _userEmail : (user?.email ?? ''),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Language Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      Translations.tr('Language', _userLanguage),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SupportedLanguages.languages.map((langMap) {
                    final displayName = langMap['name']!;
                    // Extract English name for comparison (e.g. "हिन्दी (Hindi)" -> "Hindi")
                    final englishName = displayName.contains('(')
                        ? displayName.split('(').last.replaceAll(')', '').trim()
                        : displayName;
                    final isSelected = _userLanguage.contains(englishName) || _userLanguage == displayName;
                    return GestureDetector(
                      onTap: () {
                        _changeLanguage(englishName);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGreen : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sign Out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<AuthService>().signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startVoiceAssistant() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize(
      onError: (val) {
        setState(() => _isListening = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voice error: \${val.errorMsg}')));
        }
      },
    );
    if (available) {
      setState(() => _isListening = true);
      final localeId = _getLocaleId(_userLanguage);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() => _isListening = false);
            _handleVoiceToAI(result.recognizedWords);
          }
        },
        localeId: localeId,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied or unavailable.')));
      }
    }
  }

  Future<void> _handleVoiceToAI(String query) async {
    if (query.isEmpty) return;
    
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    if (_currentSession == null) {
      _currentSession = await _sessionService.createNewSession(userId);
    }
    
    // Switch to Assistant tab instantly
    setState(() { _selectedIndex = 0; });

    // Save user's spoken text to firestore so it appears in ChatScreen
    final userMessage = ChatMessage.userText(userId, _currentSession!.id, query);
    await _firestoreService.saveMessage(userMessage);

    // Get AI response
    final aiResponse = await AIService().sendQuery(
      userId: userId, 
      sessionId: _currentSession!.id, 
      queryType: 'text', 
      content: query, 
      language: _userLanguage
    );

    await _sessionService.updateSessionOnNewMessage(_currentSession!.id, query);
    await _firestoreService.saveMessage(aiResponse);

    // Speak it back
    if (aiResponse.textContent != null) {
      final localeId = _getLocaleId(_userLanguage);
      _tts.setLanguage(localeId);
      _tts.speak(aiResponse.textContent!);
    }
  }

  String _getLocaleId(String language) {
    if (language.contains('Hindi')) return 'hi_IN';
    if (language.contains('Tamil')) return 'ta_IN';
    if (language.contains('Telugu')) return 'te_IN';
    if (language.contains('Bengali')) return 'bn_IN';
    if (language.contains('Marathi')) return 'mr_IN';
    if (language.contains('Gujarati')) return 'gu_IN';
    if (language.contains('Kannada')) return 'kn_IN';
    if (language.contains('Malayalam')) return 'ml_IN';
    if (language.contains('Punjabi')) return 'pa_IN';
    return 'en_IN';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials = _userName.isNotEmpty
        ? _userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    // Passing ValueKey(_userLanguage) forces the pages to recreate when language changes,
    // ensuring everything translates beautifully.
    final List<Widget> pages = [
      ChatScreen(key: ValueKey('chat_$_userLanguage')),
      WeatherPage(key: ValueKey('weather_$_userLanguage'), sessionId: _currentSession?.id ?? 'default', language: _userLanguage),
      MarketPage(key: ValueKey('market_$_userLanguage'), sessionId: _currentSession?.id ?? 'default', language: _userLanguage),
      DiseasePage(key: ValueKey('disease_$_userLanguage'), sessionId: _currentSession?.id ?? 'default', language: _userLanguage),
      SchemesPage(key: ValueKey('schemes_$_userLanguage'), sessionId: _currentSession?.id ?? 'default', language: _userLanguage),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          // Top Right Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Row(
              children: [
                // Reload Button
                if (_selectedIndex != 3) ...[
                  IconButton(
                    onPressed: () {
                      // Quick state flip to trigger rebuild
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    color: AppTheme.primaryGreen,
                    tooltip: 'Reload Page',
                  ),
                  const SizedBox(width: 4),
                ],
                // Global User Icon
                GestureDetector(
                  onTap: _showUserProfile,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Use standard floatingActionButton so it respects BottomNavigationBar and keyboard
      // Only show on Assistant page (index 0)
      floatingActionButton: null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: AppTheme.backgroundLight,
        indicatorColor: AppTheme.primaryGreen.withAlpha(50),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: Translations.tr('Assistant', _userLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_outlined),
            selectedIcon: const Icon(Icons.cloud),
            label: Translations.tr('Weather', _userLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: Translations.tr('Market', _userLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.eco_outlined),
            selectedIcon: const Icon(Icons.eco),
            label: Translations.tr('Crop Health', _userLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.policy_outlined),
            selectedIcon: const Icon(Icons.policy),
            label: Translations.tr('Schemes', _userLanguage),
          ),
        ],
      ),
    );
  }
}
