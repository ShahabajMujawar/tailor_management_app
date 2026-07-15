import 'package:flutter/material.dart';

/// Application theme definition complying with the Material Design 3
/// specification of the Stitch design system.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF004276);
  static const Color primaryContainerColor = Color(0xFF1a5a96);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onPrimaryContainerColor = Color(0xFFB0D1FF);

  static const Color secondaryColor = Color(0xFF535F70);
  static const Color secondaryContainerColor = Color(0xFFD7E3F8);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);
  static const Color onSecondaryContainerColor = Color(0xFF596576);

  static const Color tertiaryColor = Color(0xFF4C3A59);
  static const Color tertiaryContainerColor = Color(0xFF645171);
  static const Color onTertiaryColor = Color(0xFFFFFFFF);
  static const Color onTertiaryContainerColor = Color(0xFFDFC6ED);

  static const Color backgroundColor = Color(0xFFF9F9FF);
  static const Color onBackgroundColor = Color(0xFF181C22);

  static const Color surfaceColor = Color(0xFFF9F9FF);
  static const Color onSurfaceColor = Color(0xFF181C22);
  static const Color surfaceVariantColor = Color(0xFFE0E2EB);
  static const Color onSurfaceVariantColor = Color(0xFF424750);

  static const Color outlineColor = Color(0xFF727781);
  static const Color outlineVariantColor = Color(0xFFC2C7D1);

  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color onErrorColor = Color(0xFFFFFFFF);
  static const Color errorContainerColor = Color(0xFFFFDAD6);
  static const Color onErrorContainerColor = Color(0xFF93000A);

  // M3 Surface Container Roles
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3FC);
  static const Color surfaceContainer = Color(0xFFEBEEF6);
  static const Color surfaceContainerHigh = Color(0xFFE6E8F1);
  static const Color surfaceContainerHighest = Color(0xFFE0E2EB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        primaryContainer: primaryContainerColor,
        onPrimaryContainer: onPrimaryContainerColor,
        secondary: secondaryColor,
        onSecondary: onSecondaryColor,
        secondaryContainer: secondaryContainerColor,
        onSecondaryContainer: onSecondaryContainerColor,
        tertiary: tertiaryColor,
        onTertiary: onTertiaryColor,
        tertiaryContainer: tertiaryContainerColor,
        onTertiaryContainer: onTertiaryContainerColor,
        error: errorColor,
        onError: onErrorColor,
        errorContainer: errorContainerColor,
        onErrorContainer: onErrorContainerColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariantColor,
        outline: outlineColor,
        outlineVariant: outlineVariantColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.normal),
        displayMedium: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.normal),
        displaySmall: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.normal),
        headlineLarge: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.normal),
        headlineMedium: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.normal),
        headlineSmall: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.normal),
        titleLarge: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: outlineVariantColor, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerLowest,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerHigh,
        modalBackgroundColor: surfaceContainerHigh,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerHigh,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceVariantColor,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerHigh,
        indicatorColor: secondaryContainerColor,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
        ),
      ),
    );
  }
}
