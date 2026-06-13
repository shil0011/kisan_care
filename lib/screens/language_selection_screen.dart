import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/user_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'main_navigation_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'English'; 
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _saveLanguageAndContinue() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
        return;
      }

      final preferences = UserPreferences(
        userId: userId,
        language: _selectedLanguage,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateUserProfile(userId, preferences.toFirestore());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMoreLanguages() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemCount: SupportedLanguages.languages.length,
          itemBuilder: (context, index) {
            final language = SupportedLanguages.languages[index];
            final languageName = language['name']!;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(languageName),
                onTap: () {
                  setState(() => _selectedLanguage = languageName);
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangGridItem(String title, String subtitle, String iconStr, String langName, {bool isMore = false}) {
    bool isSelected = _selectedLanguage == langName;
    if (isMore) isSelected = false;

    return GestureDetector(
      onTap: isMore ? _showMoreLanguages : () => setState(() => _selectedLanguage = langName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isMore 
                ? Icon(Icons.language, size: 28, color: isSelected ? Colors.white : AppTheme.textDark)
                : Text(
                    iconStr,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textDark,
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Main illustration avatar
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/app_icon.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Welcome Text
                const Text(
                  'KisanCare',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C5120),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome to your digital farming\npartner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Choose Language Section
                const Text(
                  'Choose Language',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'भाषा चुनें | ਆਪਣੀ ਭਾਸ਼ਾ ਚੁਣੋ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Grid selection
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLangGridItem('English', 'Default', 'Aa', 'English'),
                    _buildLangGridItem('Hindi', 'हिन्दी', 'हि', 'Hindi'),
                    _buildLangGridItem('Punjabi', 'ਪੰਜਾਬੀ', 'ਪੰ', 'Punjabi'),
                    _buildLangGridItem('Marathi', 'मराठी', 'म', 'Marathi'),
                    _buildLangGridItem('Telugu', 'తెలుగు', 'తె', 'Telugu'),
                    _buildLangGridItem('Bengali', 'বাংলা', 'বা', 'Bengali'),
                    _buildLangGridItem('Tamil', 'தமிழ்', 'த', 'Tamil'),
                    _buildLangGridItem('Gujarati', 'ગુજરાતી', 'ગુ', 'Gujarati'),
                    _buildLangGridItem('Kannada', 'ಕನ್ನಡ', 'ಕ', 'Kannada'),
                    _buildLangGridItem('Odia', 'ଓଡ଼ିଆ', 'ଓ', 'Odia'),
                    _buildLangGridItem('Malayalam', 'മലയാളം', 'മ', 'Malayalam'),
                    _buildLangGridItem('Assamese', 'অসমীয়া', 'অ', 'Assamese'),
                    _buildLangGridItem('Maithili', 'मैथिली', 'मै', 'Maithili'),
                    _buildLangGridItem('Nepali', 'नेपाली', 'ने', 'Nepali'),
                  ],
                ),
              
              // Get started button
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveLanguageAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6F2D),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'You can also say "Start" to begin',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
