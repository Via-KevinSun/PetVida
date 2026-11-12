import 'package:flutter/material.dart';

class AppTheme {
  static const teal = Color(0xFF4DB6AC);
  static const peach = Color(0xFFFFAB91);
  static const sand = Color(0xFFF6FAF9);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: teal, secondary: peach, surface: Colors.white);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: sand,
      appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: sand, elevation: 0, scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(color: Color(0xFF263238), fontSize: 20, fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: Color(0xFF263238))),
        cardTheme: CardThemeData(
        elevation: 0, color: Colors.white, margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.teal.shade50)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.teal.shade100)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.teal.shade100)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    );
  }
}
