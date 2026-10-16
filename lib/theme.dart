import 'package:flutter/material.dart';

const ink = Color(0xff172c35);
const muted = Color(0xff6c7d84);
const accent = Color(0xff167d68);

extension PocketColors on BuildContext {
  ColorScheme get palette => Theme.of(this).colorScheme;
  Color get appInk => palette.onSurface;
  Color get appMuted => palette.onSurfaceVariant;
  Color get appAccent => palette.primary;
  Color get appSurface => palette.surface;
  Color get appPanel => palette.surfaceContainerLow;
}

ThemeData pocketTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
    surface: dark ? const Color(0xff162328) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xff0e191e)
        : const Color(0xfff3f6f7),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -1,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: scheme.onSurface, height: 1.5),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
    ),
  );
}

IconData categoryIcon(String value) => switch (value) {
  'Food' => Icons.restaurant_rounded,
  'Transport' => Icons.directions_bus_rounded,
  'Shopping' => Icons.shopping_bag_outlined,
  'Bills' => Icons.receipt_long_rounded,
  'Health' => Icons.favorite_outline,
  'Education' => Icons.school_outlined,
  _ => Icons.grid_view_rounded,
};
Color categoryColor(String value) => switch (value) {
  'Food' => const Color(0xffdb8b38),
  'Transport' => const Color(0xff5286cc),
  'Shopping' => const Color(0xff9a70c8),
  'Bills' => const Color(0xffd36d80),
  'Health' => const Color(0xff42a693),
  'Education' => const Color(0xff7080b8),
  _ => const Color(0xff7b8b92),
};
