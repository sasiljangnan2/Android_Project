import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xff173e2d);
  static const lime = Color(0xffd5f45b);
  static const background = Color(0xfff7f8f2);
  static const error = Color(0xffb4232a);
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    brightness: brightness,
    primary: dark ? AppColors.lime : AppColors.ink,
    onPrimary: dark ? AppColors.ink : Colors.white,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    surface: dark ? const Color(0xff1c2721) : Colors.white,
    error: dark ? const Color(0xffffb4ab) : AppColors.error,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: dark
        ? const Color(0xff121b16)
        : AppColors.background,
    textTheme: base.textTheme.apply(
      fontFamily: 'Pretendard',
      bodyColor: dark ? const Color(0xffedf3e8) : AppColors.ink,
      displayColor: dark ? const Color(0xffedf3e8) : AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xff121b16) : AppColors.background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Pretendard',
        color: scheme.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: scheme.outlineVariant,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.ink,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: dark ? const Color(0xff34482d) : const Color(0xffedf3df),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
