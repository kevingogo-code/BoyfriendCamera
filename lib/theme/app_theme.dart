import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF087FFF);
  static const green = Color(0xFF2FC264);
  static const orange = Color(0xFFFF9F0A);
  static const text = Color(0xFF111111);
  static const secondaryText = Color(0xFF7C7C83);
  static const line = Color(0xFFE1E1E6);
  static const fill = Color(0xFFF2F2F7);
  static const page = Color(0xFFFFFFFF);
}

ThemeData buildAppTheme({String? fontFamily}) {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.page,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      surface: AppColors.page,
    ),
    fontFamily: fontFamily,
    fontFamilyFallback: const ['PingFang SC', 'Noto Sans CJK SC'],
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text, fontSize: 15),
      titleLarge: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.page,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: AppColors.blue,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    useMaterial3: true,
  );
}
