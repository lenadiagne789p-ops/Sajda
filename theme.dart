import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IslamicColors {
  static const emeraldGreen = Color(0xFF1B5E20);
  static const roseGold = Color(0xFFD4AF37);
  static const pearlWhite = Color(0xFFFAFAFA);
  static const mysticBlue = Color(0xFF1A237E);
  static const dustyRose = Color(0xFFE8B4CB);
  static const softViolet = Color(0xFF9575CD);
  // Gemstone palette
  static const rubyRed = Color(0xFFB71C1C);
  static const sapphireBlue = Color(0xFF0D47A1);
  static const amethystPurple = Color(0xFF6A1B9A);
  static const emerald = emeraldGreen; // alias
  static const opalIridescent = Color(0xFF64B5F6);
  static const quartz = Color(0xFFB0BEC5);
  static const topaz = Color(0xFFFFB300);
  static const onyx = Color(0xFF263238);

  // Tajweed highlighting palette (soft but distinct)
  static const tajweedIkhfa = Color(0xFF43A047); // green
  static const tajweedIdgham = Color(0xFF8E24AA); // purple
  static const tajweedIqlab = Color(0xFFFB8C00); // orange
  static const tajweedQalqalah = Color(0xFFE53935); // red
  static const tajweedGhunnah = Color(0xFF1E88E5); // blue

  // Arabic diacritics (vowel marks) palette
  // Readable on both light and dark backgrounds
  static const vowelFatha = Color(0xFFEF5350); // soft red
  static const vowelKasra = Color(0xFF26A69A); // teal
  static const vowelDamma = Color(0xFF5C6BC0); // indigo
  static const vowelSukun = Color(0xFF8D6E63); // neutral
  static const vowelShadda = Color(0xFFAB47BC); // purple accent
  static const vowelTanween = Color(0xFF009688); // greenish cyan
}

// Curated gradients used across the app for emphasis and surfaces
class AppGradients {
  static const LinearGradient emeraldAurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B5E20), // emerald start
      Color(0xFF2E7D32), // emerald mid
    ],
    tileMode: TileMode.clamp,
  );

  static const LinearGradient roseHalo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x4DD4AF37), // rose gold 30%
      Color(0x1AD4AF37), // rose gold 10%
    ],
    tileMode: TileMode.clamp,
  );

  static const LinearGradient violetMist = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x339575CD), // soft violet 20%
      Color(0x1A1A237E), // mystic blue 10%
    ],
    tileMode: TileMode.clamp,
  );
}

class LightModeColors {
  static const lightPrimary = IslamicColors.emeraldGreen;
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFC8E6C9);
  static const lightOnPrimaryContainer = Color(0xFF1B5E20);
  static const lightSecondary = IslamicColors.roseGold;
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = IslamicColors.mysticBlue;
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);
  static const lightInversePrimary = Color(0xFF81C784);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = IslamicColors.pearlWhite;
  static const lightOnSurface = Color(0xFF1C1C1C);
  static const lightAppBarBackground = Color(0xFFC8E6C9);
}

class DarkModeColors {
  static const darkPrimary = Color(0xFF4CAF50);
  static const darkOnPrimary = Color(0xFF1B5E20);
  static const darkPrimaryContainer = Color(0xFF2E7D32);
  static const darkOnPrimaryContainer = Color(0xFFC8E6C9);
  static const darkSecondary = IslamicColors.roseGold;
  static const darkOnSecondary = Color(0xFF1C1C1C);
  static const darkTertiary = IslamicColors.softViolet;
  static const darkOnTertiary = Color(0xFF1C1C1C);
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);
  static const darkInversePrimary = IslamicColors.emeraldGreen;
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF121212);
  static const darkOnSurface = Color(0xFFE0E0E0);
  static const darkAppBarBackground = Color(0xFF2E7D32);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

TextTheme _withFallback(TextTheme base, List<String> fallback) {
  TextStyle? f(TextStyle? s) => s?.copyWith(fontFamilyFallback: fallback);
  return base.copyWith(
    displayLarge: f(base.displayLarge),
    displayMedium: f(base.displayMedium),
    displaySmall: f(base.displaySmall),
    headlineLarge: f(base.headlineLarge),
    headlineMedium: f(base.headlineMedium),
    headlineSmall: f(base.headlineSmall),
    titleLarge: f(base.titleLarge),
    titleMedium: f(base.titleMedium),
    titleSmall: f(base.titleSmall),
    labelLarge: f(base.labelLarge),
    labelMedium: f(base.labelMedium),
    labelSmall: f(base.labelSmall),
    bodyLarge: f(base.bodyLarge),
    bodyMedium: f(base.bodyMedium),
    bodySmall: f(base.bodySmall),
  );
}

ThemeData get lightTheme {
  final arabicPrimary = GoogleFonts.notoNaskhArabic();
  final arabicSans = GoogleFonts.notoSansArabic();
  final fallback = [
    arabicPrimary.fontFamily ?? 'Noto Naskh Arabic',
    arabicSans.fontFamily ?? 'Noto Sans Arabic',
    'system-ui',
  ];

  final baseText = TextTheme(
    displayLarge: GoogleFonts.inter(fontSize: FontSizes.displayLarge, fontWeight: FontWeight.normal),
    displayMedium: GoogleFonts.inter(fontSize: FontSizes.displayMedium, fontWeight: FontWeight.normal),
    displaySmall: GoogleFonts.inter(fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w600),
    headlineLarge: GoogleFonts.inter(fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.normal),
    headlineMedium: GoogleFonts.inter(fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w500),
    headlineSmall: GoogleFonts.inter(fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.bold),
    titleLarge: GoogleFonts.inter(fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w500),
    titleMedium: GoogleFonts.inter(fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w500),
    titleSmall: GoogleFonts.inter(fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500),
    labelLarge: GoogleFonts.inter(fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500),
    labelMedium: GoogleFonts.inter(fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.inter(fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.inter(fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.normal),
    bodyMedium: GoogleFonts.inter(fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.normal),
    bodySmall: GoogleFonts.inter(fontSize: FontSizes.bodySmall, fontWeight: FontWeight.normal),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: LightModeColors.lightPrimary,
      onPrimary: LightModeColors.lightOnPrimary,
      primaryContainer: LightModeColors.lightPrimaryContainer,
      onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
      secondary: LightModeColors.lightSecondary,
      onSecondary: LightModeColors.lightOnSecondary,
      tertiary: LightModeColors.lightTertiary,
      onTertiary: LightModeColors.lightOnTertiary,
      error: LightModeColors.lightError,
      onError: LightModeColors.lightOnError,
      errorContainer: LightModeColors.lightErrorContainer,
      onErrorContainer: LightModeColors.lightOnErrorContainer,
      inversePrimary: LightModeColors.lightInversePrimary,
      shadow: LightModeColors.lightShadow,
      surface: LightModeColors.lightSurface,
      onSurface: LightModeColors.lightOnSurface,
    ),
    brightness: Brightness.light,
    // Solid white background across the app (no global images)
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: LightModeColors.lightOnPrimaryContainer,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: IslamicColors.emeraldGreen,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: IslamicColors.roseGold,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
    ),
    textTheme: _withFallback(baseText, fallback),
    iconTheme: const IconThemeData(color: IslamicColors.emeraldGreen, size: 22),
    cardTheme: const CardThemeData(
      color: Colors.white,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: IslamicColors.emeraldGreen.withValues(alpha: 0.95),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: IslamicColors.quartz.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: IslamicColors.quartz.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: IslamicColors.emeraldGreen, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(IslamicColors.emeraldGreen),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.05)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(IslamicColors.roseGold),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: IslamicColors.emeraldGreen.withValues(alpha: 0.6))),
        foregroundColor: const WidgetStatePropertyAll(IslamicColors.emeraldGreen),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: IslamicColors.emeraldGreen.withValues(alpha: 0.08),
      selectedColor: IslamicColors.emeraldGreen,
      secondarySelectedColor: IslamicColors.emeraldGreen,
      labelStyle: const TextStyle(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    visualDensity: VisualDensity.standard,
  );
}

ThemeData get darkTheme {
  final arabicPrimary = GoogleFonts.notoNaskhArabic();
  final arabicSans = GoogleFonts.notoSansArabic();
  final fallback = [
    arabicPrimary.fontFamily ?? 'Noto Naskh Arabic',
    arabicSans.fontFamily ?? 'Noto Sans Arabic',
    'system-ui',
  ];

  final baseText = TextTheme(
    displayLarge: GoogleFonts.inter(fontSize: FontSizes.displayLarge, fontWeight: FontWeight.normal),
    displayMedium: GoogleFonts.inter(fontSize: FontSizes.displayMedium, fontWeight: FontWeight.normal),
    displaySmall: GoogleFonts.inter(fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w600),
    headlineLarge: GoogleFonts.inter(fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.normal),
    headlineMedium: GoogleFonts.inter(fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w500),
    headlineSmall: GoogleFonts.inter(fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.bold),
    titleLarge: GoogleFonts.inter(fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w500),
    titleMedium: GoogleFonts.inter(fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w500),
    titleSmall: GoogleFonts.inter(fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500),
    labelLarge: GoogleFonts.inter(fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500),
    labelMedium: GoogleFonts.inter(fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.inter(fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.inter(fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.normal),
    bodyMedium: GoogleFonts.inter(fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.normal),
    bodySmall: GoogleFonts.inter(fontSize: FontSizes.bodySmall, fontWeight: FontWeight.normal),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: DarkModeColors.darkPrimary,
      onPrimary: DarkModeColors.darkOnPrimary,
      primaryContainer: DarkModeColors.darkPrimaryContainer,
      onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
      secondary: DarkModeColors.darkSecondary,
      onSecondary: DarkModeColors.darkOnSecondary,
      tertiary: DarkModeColors.darkTertiary,
      onTertiary: DarkModeColors.darkOnTertiary,
      error: DarkModeColors.darkError,
      onError: DarkModeColors.darkOnError,
      errorContainer: DarkModeColors.darkErrorContainer,
      onErrorContainer: DarkModeColors.darkOnErrorContainer,
      inversePrimary: DarkModeColors.darkInversePrimary,
      shadow: DarkModeColors.darkShadow,
      surface: DarkModeColors.darkSurface,
      onSurface: DarkModeColors.darkOnSurface,
    ),
    brightness: Brightness.dark,
    // Use solid dark surface when ambient background is disabled
    scaffoldBackgroundColor: DarkModeColors.darkSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: DarkModeColors.darkOnPrimaryContainer,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF121212),
      selectedItemColor: IslamicColors.roseGold,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: IslamicColors.roseGold,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
    ),
    textTheme: _withFallback(baseText, fallback),
    iconTheme: const IconThemeData(color: Colors.white70, size: 22),
    cardTheme: const CardThemeData(
      color: Color(0xFF161616),
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: IslamicColors.roseGold.withValues(alpha: 0.95),
      contentTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      backgroundColor: Color(0xFF121212),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF141414),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: IslamicColors.quartz.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: IslamicColors.quartz.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: IslamicColors.roseGold, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(DarkModeColors.darkPrimary),
        foregroundColor: const WidgetStatePropertyAll(Colors.black),
        overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.06)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(IslamicColors.roseGold),
        foregroundColor: const WidgetStatePropertyAll(Colors.black),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: Colors.white.withValues(alpha: 0.6))),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      selectedColor: IslamicColors.roseGold,
      secondarySelectedColor: IslamicColors.roseGold,
      labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    visualDensity: VisualDensity.standard,
  );
}
