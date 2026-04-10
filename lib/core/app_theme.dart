import 'package:flutter/material.dart';

class AppTheme {
  // Derin kozmik renkler
  // Müşterinin yeni paleti (Modern Deep Blue & Amber)
  static const Color primaryColor = Color(0xFFF59E0B); // Amber Accent
  static const Color secondaryColor = Color(0xFFFBBF24); // Gold Highlight
  static const Color backgroundColor = Color(0xFF0F172A); // Deep Navy Primary
  static const Color gradientEndColor = Color(0xFF1E3A8A); // Blue Gradient
  static const Color cardColor = Color(0xFF1E293B); // Slate/Navy blend for cards

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: cardColor.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryColor;
          }
          return Colors.white10;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      useMaterial3: true,
    );
  }
}

