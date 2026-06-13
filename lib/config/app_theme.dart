import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - "Organic Editorialism" - The Digital Soil
  static const Color primaryGreen = Color(0xFF0D631B); // primary
  static const Color secondaryBrown = Color(0xFF75584D); // secondary
  static const Color accentOrange = Color(0xFF6E5100); // tertiary
  static const Color accentYellow = Color(0xFF88D982); // primary_fixed_dim
  
  static const Color userBubbleBlue = Color(0xFF2E7D32); // primary_container
  static const Color aiBubbleGrey = Color(0xFFEEEEEE); // surface_container
  static const Color textDark = Color(0xFF1A1C1C); // on_surface
  static const Color textLight = Color(0xFFFFFFFF); // on_primary & surface_container_lowest
  static const Color textSecondary = Color(0xFF40493D); // on_surface_variant
  
  static const Color backgroundLight = Color(0xFFF9F9F9); // surface
  static const Color cardBackground = Color(0xFFFFFFFF); // surface_container_lowest
  static const Color borderColor = Color(0xFFBFCABA); // outline_variant (use with opacity)
  
  static const Color successGreen = Color(0xFF2E7D32); // primary_container (adjusted for theme)
  static const Color warningRed = Color(0xFFBA1A1A); // error
  static const Color infoBlue = Color(0xFF2E7D32); // info mapped to primary container

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Lexend', // Base font strategy for body & labels
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentOrange,
        surface: cardBackground,
        error: warningRed,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight, // Shift to earthy, borderless tone
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans', // Headlines & display
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
      
      // Text Theme - Large and Clear
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 36, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        displaySmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        headlineMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 22, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w500, color: textDark),
        bodyLarge: TextStyle(fontFamily: 'Lexend', fontSize: 16, color: textDark, height: 1.5),
        bodyMedium: TextStyle(fontFamily: 'Lexend', fontSize: 14, color: textDark, height: 1.5),
        labelLarge: TextStyle(fontFamily: 'Lexend', fontSize: 16, fontWeight: FontWeight.w600, color: textLight),
      ),
      
      // Input Decoration Theme ("Selection Blocks" sized inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE8E8E8), // surface_container_high
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none, // "No-Line" Rule
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: warningRed, width: 2),
        ),
        hintStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, color: textSecondary),
        labelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, color: textSecondary),
      ),
      
      // Elevated Button Theme (The Voice Core type buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textLight,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32), // roundedness-full approximation
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
          ),
          elevation: 4, // "Tonal Layering" tactile depth
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        color: Color(0xFFF3F3F3), // surface_container_low
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)), // roundedness-lg standard
        ),
        margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFF6E5100), // tertiary for icons
        size: 28,
      ),
    );
  }
}
