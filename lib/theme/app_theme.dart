import 'package:flutter/material.dart';
import '../models/task.dart';

class AppColors {
  static const primary = Color(0xFF3D3BF3);
  static const background = Color(0xFFF2F2F7);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const divider = Color(0xFFE5E5EA);
  static const overdueRed = Color(0xFFFF3B5C);
  static const priorityHigh = Color(0xFFFF3B5C);
  static const priorityMedium = Color(0xFFFF9500);
  static const priorityLow = Color(0xFF34C759);

  // Dark mode equivalents
  static const darkBackground = Color(0xFF1C1C1E);
  static const darkCard = Color(0xFF2C2C2E);
  static const darkDivider = Color(0xFF3A3A3C);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF8E8E93);

  static Color priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return priorityHigh;
      case TaskPriority.medium:
        return priorityMedium;
      case TaskPriority.low:
        return priorityLow;
      case TaskPriority.none:
        return Colors.transparent;
    }
  }
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.card,
        dividerColor: AppColors.divider,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.primary),
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          titleMedium: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
          bodyMedium: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
          labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textSecondary),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle:  TextStyle(color: AppColors.textSecondary, fontSize: 15),
          filled: false,
          isDense: true,
          contentPadding:  EdgeInsets.symmetric(vertical: 8),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        dividerColor: AppColors.darkDivider,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.primary),
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.darkTextPrimary),
          titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
          titleMedium: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
          bodyLarge: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.darkTextPrimary),
          bodyMedium: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.darkTextSecondary),
          labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.darkTextSecondary),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 15),
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF3A3A3C),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
}