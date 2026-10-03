import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String pixelFont = 'Galmuri11';

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: pixelFont,
      scaffoldBackgroundColor: AppColors.night,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.purple,
        surface: AppColors.nightPanel,
        onPrimary: AppColors.night,
        onSurface: AppColors.text,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: pixelFont,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    );
  }
}
