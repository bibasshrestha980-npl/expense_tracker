import 'package:flutter/material.dart';

const ink = Color(0xff172c35);
const muted = Color(0xff6c7d84);
const accent = Color(0xff167d68);
ThemeData pocketTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: accent, surface: Colors.white),
  scaffoldBackgroundColor: const Color(0xfff3f6f7),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: ink,
      letterSpacing: -1,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xffe5ecee)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xffedf1f2), thickness: 1),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xfff8fafb),
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffdce5e8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffdce5e8)),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Color(0xffdcefe9),
  ),
);

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
