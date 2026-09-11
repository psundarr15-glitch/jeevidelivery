import 'package:flutter/material.dart';

/// Jeevi Foodie Delivery Partner design system.
/// UX direction: fast scanning, high contrast and action-first.  Online state,
/// active deliveries and the next required action should be obvious at a glance.
class AppTheme {
  static const primary = Color(0xFFD6291B);
  static const primaryDark = Color(0xFF8E1610);
  static const gold = Color(0xFFF7B500);
  static const success = Color(0xFF159447);
  static const canvas = Color(0xFFF7F8F6);
  static const cardShadow = [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))];

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1D1E1C) : Colors.white;
  static Color scaffoldBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E211F);
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF6E746F);
  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE0E5E1);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: Color(0xFF1E211F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF1E211F)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: primary, minimumSize: const Size(0, 50), side: const BorderSide(color: Color(0xFFE0B5B0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.6)),
      ),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      chipTheme: ChipThemeData(backgroundColor: const Color(0xFFEEF1EE), selectedColor: primary.withOpacity(.10), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      dialogTheme: DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E211F))),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, showDragHandle: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26)))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        height: 72,
        elevation: 8,
        indicatorColor: primary.withOpacity(.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 10.5, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w600, color: states.contains(WidgetState.selected) ? primary : const Color(0xFF6E746F))),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(size: 24, color: states.contains(WidgetState.selected) ? primary : const Color(0xFF6E746F))),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E9E6), thickness: 1, space: 1),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF121412),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false, surfaceTintColor: Colors.transparent),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.6))),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26)))),
      navigationBarTheme: NavigationBarThemeData(height: 72, indicatorColor: primary.withOpacity(.24)),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark ? Colors.white : const Color(0xFF1E211F);
    final muted = brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF6E746F);
    return TextTheme(
      headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: base),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: base),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: base),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: base, height: 1.4),
      bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: base),
    );
  }
}
