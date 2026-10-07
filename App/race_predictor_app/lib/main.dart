import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RacePredictorApp());
}

// Global theme notifier to control dark/light mode from anywhere
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class RacePredictorApp extends StatelessWidget {
  const RacePredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A73E8);
    const secondaryGreen = Color(0xFF34A853);
    const tertiaryGrey = Color(0xFF5F6368);
    const backgroundGray = Color(0xFFF8F9FA);
    const errorRed = Color(0xFFD93025);
    
    // Common ColorScheme base
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: secondaryGreen,
      tertiary: tertiaryGrey,
      surface: Colors.white,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Colors.black87,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: primaryBlue,
      secondary: secondaryGreen,
      tertiary: Colors.grey.shade400,
      surface: const Color(0xFF1E1E1E),
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.black87,
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF2C2C2C),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Race Predictor',
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            scaffoldBackgroundColor: backgroundGray,
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
              bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
              bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
              labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: primaryBlue),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              labelStyle: const TextStyle(color: Colors.grey),
              prefixIconColor: primaryBlue,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                elevation: 0,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            scaffoldBackgroundColor: const Color(0xFF121212),
            textTheme: TextTheme(
              headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              bodyLarge: const TextStyle(fontSize: 16, color: Colors.white70),
              bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
              bodySmall: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: primaryBlue),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
              margin: const EdgeInsets.all(0),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              labelStyle: TextStyle(color: Colors.grey.shade400),
              prefixIconColor: primaryBlue,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                elevation: 0,
              ),
            ),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}