import 'package:flutter/material.dart';

/// Jeevi Foodie premium design system.  The visual language is intentionally
/// shared across the customer, restaurant and delivery apps: warm neutral
/// canvas, white elevated surfaces, bold typography, soft 16-26px radii,
/// colored "floating" shadows on primary actions, and a red brand action
/// color with gold accents.  Individual apps only differ in navigation and
/// content — this file is the single source of truth for spacing, radius,
/// shadow and gradient tokens so every screen reads as one product.
class AppTheme {
  static const primary = Color(0xFFF22549);
  static const primaryDark = Color(0xFFC91436);
  static const gold = Color(0xFFF7A600);
  static const goldDark = Color(0xFFD98600);
  static const success = Color(0xFF12A968);
  static const canvas = Color(0xFFF8F7F4);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF697386);
  static const line = Color(0xFFE8E9ED);
  static const softRed = Color(0xFFFFEEF1);
  static const softGreen = Color(0xFFE9FAF2);
  static const softOrange = Color(0xFFFFF3E1);

  // ---- Radius scale ------------------------------------------------------
  static const radiusSm = 10.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 26.0;
  static const radiusPill = 999.0;

  // ---- Spacing scale -------------------------------------------------------
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;

  // ---- Gradients -----------------------------------------------------------
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDark],
  );
  static const canvasGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), canvas],
  );

  /// Legacy alias kept for existing call sites.
  static const cardShadow = [
    BoxShadow(color: Color(0x120E1726), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Soft resting shadow for cards/tiles on a light canvas.
  static List<BoxShadow> shadowSoft(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.35)
              : const Color(0x0F172033),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Deeper "floating" shadow for hero cards, sheets and premium banners.
  static List<BoxShadow> shadowElevated(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.45)
              : const Color(0x1A172033),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  /// Brand-colored glow used under primary CTAs / floating action buttons
  /// so they read as "lifted" rather than flat filled rectangles.
  static List<BoxShadow> shadowColored(
    Color color, {
    double opacity = 0.32,
    double blur = 22,
    Offset offset = const Offset(0, 10),
  }) =>
      [BoxShadow(color: color.withOpacity(opacity), blurRadius: blur, offset: offset)];

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF211D1E) : Colors.white;
  static Color scaffoldBg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : ink;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : muted;
  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : line;

  /// Frosted, semi-transparent panel color for overlays sitting on top of
  /// imagery (e.g. a rating pill on a food photo) so premium screens don't
  /// default to a plain opaque white box everywhere.
  static Color glassSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withOpacity(0.55)
          : Colors.white.withOpacity(0.85);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ink, letterSpacing: -0.7),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink, letterSpacing: -0.9),
        headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink, letterSpacing: -0.6),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 15, color: ink, height: 1.35),
        bodyMedium: TextStyle(fontSize: 14, color: muted, height: 1.35),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: softRed,
        disabledColor: line,
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      tabBarTheme: const TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: primary,
        unselectedLabelColor: muted,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFCFBFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: primary, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: Color(0xFFE5484D))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withOpacity(0.4),
          minimumSize: const Size.fromHeight(54),
          elevation: 2,
          shadowColor: primary.withOpacity(0.45),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: 0.1),
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: primary, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44), tapTargetSize: MaterialTapTargetSize.padded),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 10,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        showDragHandle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        indicatorColor: softRed,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
              color: states.contains(WidgetState.selected) ? primary : muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? primary : muted,
            )),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF141213),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141213),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.7),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF211D1E),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF211D1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: Color(0xFF3A3536))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMd), borderSide: const BorderSide(color: primary, width: 1.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 2,
          shadowColor: primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF211D1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF211D1E),
        modalBackgroundColor: const Color(0xFF211D1E),
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: const Color(0xFF211D1E),
        indicatorColor: primary.withOpacity(0.22),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
      ),
    );
  }
}
