import 'package:flutter/material.dart';

/// Colors matched to the "Jeevi Foodie" red/yellow/white logo: a strong
/// appetizing red as the primary brand color, gold/yellow for CTA
/// accents and badges (splash, "ORDER NOW", ratings), white for cards
/// and surfaces.
///
/// Universal status colors elsewhere in the app (veg = green dot,
/// non-veg = red dot, wallet credit = green / debit = red, completed
/// order step = green check) are intentionally left as-is - those are
/// standard conventions users already recognize, not brand color, so
/// changing them to fit a red/yellow/white palette would make the app
/// harder to read rather than more on-brand.
class AppTheme {
  static const primary = Color(0xFFD6291B); // brand red
  static const primaryDark = Color(0xFF8E1610); // deep red/maroon
  static const gold = Color(0xFFF7B500); // CTA accent on dark/red backgrounds
  static const success = Color(0xFFD6291B); // rating badges / accent text on white cards

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      scaffoldBackgroundColor: const Color(0xFFFFFBF5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
            color: states.contains(WidgetState.selected) ? primary : Colors.grey.shade600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? primary : Colors.grey.shade600),
        ),
      ),
    );
  }
}
