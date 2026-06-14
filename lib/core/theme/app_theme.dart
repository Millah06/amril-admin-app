import 'package:flutter/material.dart';

/// Central theme configuration for the admin app.
/// All colors and text styles should come from here — never hardcoded.
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 🎨 Base Colors
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceVariant = Color(0xFF334155);

  static const Color primary = Color(0xFF21D3ED);
  static const Color accent = Color(0xFF10B981);

  // ✅ Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color pending = Color(0xFFFBBF24);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color divider = Color(0xFF1E293B);

  static const Color cardBg = surface;

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.dark(
        background: background,
        surface: surface,
        primary: primary,
        secondary: success,     // 👈 map success here
        error: danger,
      ),

      // 🧠 APP BAR
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // 📦 CARDS
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: divider),
        ),
      ),

      // ✍️ INPUTS
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),

      // 🔘 BUTTONS
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // 🧾 TEXT
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
      ),

      dividerTheme: const DividerThemeData(color: divider, thickness: 1),

      // 📱 NAV
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
      ),
    );
  }
}