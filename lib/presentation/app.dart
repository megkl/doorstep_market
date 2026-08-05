import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';

class DoorstepMarketApp extends StatelessWidget {
  const DoorstepMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E9B57),
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFF6F7F1),
          surfaceContainerHighest: Colors.white,
          primary: const Color(0xFF2E9B57),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF16211D),
          tertiary: const Color(0xFFE3EEE8),
          onTertiary: const Color(0xFF16211D),
          outline: const Color(0xFFD8DFD2),
        );

    return MaterialApp(
      title: 'Doorstep Market',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(Typography.material2021().black)
            .apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: colorScheme.surfaceContainerHighest,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: colorScheme.surfaceContainerHighest,
          indicatorColor: colorScheme.primary.withAlpha(31),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
