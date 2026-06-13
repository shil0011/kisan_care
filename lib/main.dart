import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_options.dart';
import 'config/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/language_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file not found. Make sure to create one based on .env.example");
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: const KisanCareApp(),
    ),
  );
}

class KisanCareApp extends StatelessWidget {
  const KisanCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KisanCare',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        
        // Use FutureBuilder to check if user has already selected a language
        return FutureBuilder<Map<String, dynamic>?>(
          future: firestoreService.getUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            final profile = profileSnapshot.data;
            if (profile != null && profile['language'] != null) {
              return const MainNavigationScreen();
            } else {
              return const LanguageSelectionScreen();
            }
          },
        );
      },
    );
  }
}
