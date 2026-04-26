import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Accent / Brand ──────────────────────────────────────────
  static const primary = Color(0xFF317BFF);
  static const primaryHover = Color(0xFF2763CE);
  static const primaryLight = Color(0xFFEAF2FF);
  static const primaryLightDark = Color(0x21317BFF);

  // ── Semantic ────────────────────────────────────────────────
  static const error = Color(0xFFEE2750);
  static const errorDark = Color(0xFFBE1F40);
  static const errorLightBg = Color(0xFFFFF2F5);
  static const errorLightBgDark = Color(0xFF4E353A);

  static const success = Color(0xFF3DA43B);
  static const successHover = Color(0xFF348E33);
  static const successText = Color(0xFF63C662);

  // ── Mono / Data visualization ───────────────────────────────
  static const blue = Color(0xFF317BFF);
  static const green = Color(0xFF3DA43B);
  static const green2 = Color(0xFF1CC14D);
  static const orange = Color(0xFFF0681B);
  static const purple = Color(0xFFB13AFB);
  static const sepia = Color(0xFFD76556);
  static const darkGray = Color(0xFF474D6C);

  // ── Light-only helpers ──────────────────────────────────────
  static const lightScaffold = Color(0xFFF5F6F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBack2 = Color(0xFFF1F1F7);
  static const lightOnSurface = Color(0xFF0A1B39);
  static const lightOnSurfaceVariant = Color(0xFF83899F);
  static const lightSecondaryDark = Color(0xFF676E85);
  static const lightSecondaryLight = Color(0xFF9CA0B2);
  static const lightSecondaryExtraLight = Color(0xFFD8DBE4);
  static const lightPrimaryLight = Color(0xFF485066);
  static const lightDivider = Color(0xFFE6E7EC);
  static const lightDividerLight = Color(0xFFEDEEF3);
  static const lightDividerStrong = Color(0xFFD7D9E2);
  static const lightInverse = Color(0xFF31394A);
  static const lightAccentLight = Color(0xFF83B0FF);
  static const lightOnBack4 = Color(0xFFFFFFFF);
  static const lightUnderBack = Color(0xFFE0E4EC);
  static const lightDisabledBg = Color(0xFFE8EBEF);
  static const lightDisabledContent = Color(0xFF9CA1B2);

  // ── Dark-only helpers ───────────────────────────────────────
  static const darkScaffold = Color(0xFF14161B);
  static const darkSurface = Color(0xFF21262D);
  static const darkBack2 = Color(0xFF101115);
  static const darkSurface2 = Color(0xFF292E37);
  static const darkSurface3 = Color(0xFF2B313A);
  static const darkSurfaceElevated = Color(0xFF3B434F);
  static const darkOnSurface = Color(0xFFFFFFFF);
  static const darkOnSurfaceVariant = Color(0xFF686F87);
  static const darkSecondaryDark = Color(0xFF9CA0B2);
  static const darkSecondaryLight = Color(0xFF4D546B);
  static const darkSecondaryExtraLight = Color(0xFF3D4357);
  static const darkPrimaryLight = Color(0xB3FFFFFF);
  static const darkDivider = Color(0xFF313843);
  static const darkDividerLight = Color(0xFF262C34);
  static const darkDividerStrong = Color(0xFF3E4551);
  static const darkOnBack4 = Color(0xFF1A1C22);
  static const darkUnderBack = Color(0xFF000000);
  static const darkDisabledBg = Color(0x12E7EFFE);
  static const darkDisabledContent = Color(0xFF5D6273);

  // ── Orange background ───────────────────────────────────────
  static const orangeLightBg = Color(0xFFFEF3E2);
  static const orangeLightBgDark = Color(0xFF44413C);

  // ── Neutral button ────────────────────────────────────────
  static const neutralBtnBack = Color(0xFF272C35);
  static const neutralBtnBackLight = Color(0xFFF0F1F5);
  static const neutralBtnContent = Color(0xFFFFFFFF);
  static const neutralBtnContentLight = Color(0xFF0A1B39);

  // ── Line tokens (DT = dark-theme transparency variants) ───
  /// Dark-theme line @ 5% on #CDDEFF (was 10% / 0x1A).
  static const lineDT100 = Color(0x0DCDDEFF);
  static const lineDT200 = Color(0x1ACDDEFF);
  static const lineDT300 = Color(0x1ACDDEFF);
  static const lineLight100 = Color(0xFFEDEEF3);
  static const lineLight200 = Color(0xFFE6E7EC);
  static const lineLight300 = Color(0xFFD7D9E2);
}

class AppTheme {
  AppTheme._();

  static const lightBarShadow = [
    BoxShadow(color: Color(0x12000000), blurRadius: 16),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2),
  ];

  static const darkBarShadow = [
    BoxShadow(color: Color(0x29000000), blurRadius: 16),
    BoxShadow(color: Color(0x14000000), blurRadius: 2),
  ];

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.lightOnSurface,
      secondary: AppColors.lightOnSurfaceVariant,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.primaryLight,
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.orange,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.orangeLightBg,
      onTertiaryContainer: AppColors.orange,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLightBg,
      onErrorContainer: AppColors.errorDark,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.lightScaffold,
      surfaceContainer: AppColors.lightScaffold,
      surfaceContainerHigh: AppColors.lightUnderBack,
      surfaceContainerHighest: AppColors.lightUnderBack,
      outline: AppColors.lightDivider,
      outlineVariant: AppColors.lightDividerLight,
      inverseSurface: AppColors.lightInverse,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.lightAccentLight,
      scrim: Color(0x80262E3D),
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightScaffold,
      dividerColor: AppColors.lightDivider,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 4,
        scrolledUnderElevation: 4,
        shadowColor: const Color(0x12000000),
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        backgroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        overlayColor: WidgetStateProperty.all(AppColors.lightSurface.withAlpha(20)),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLightDark,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.darkOnSurfaceVariant,
      onSecondary: Colors.white,
      secondaryContainer: Color(0x1A5F92E5),
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.orange,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.orangeLightBgDark,
      onTertiaryContainer: AppColors.orange,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLightBgDark,
      onErrorContainer: AppColors.error,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      surfaceContainerLowest: AppColors.darkUnderBack,
      surfaceContainerLow: AppColors.darkScaffold,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurface2,
      surfaceContainerHighest: AppColors.darkSurface3,
      outline: AppColors.darkDivider,
      outlineVariant: AppColors.darkDividerLight,
      inverseSurface: Colors.white,
      onInverseSurface: Color(0xFF262E3D),
      inversePrimary: AppColors.primary,
      scrim: Color(0x80000000),
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      dividerColor: AppColors.darkDivider,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 4,
        scrolledUnderElevation: 4,
        shadowColor: const Color(0x29000000),
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        backgroundColor: AppColors.darkSurface,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        overlayColor: WidgetStateProperty.all(AppColors.darkSurface.withAlpha(40)),
      ),
    );
  }
}
