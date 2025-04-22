import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color primaryStart = Color(0xFF2C3E50);
  static const Color primaryEnd = Color(0xFF627180);
  
  // Additional colors
  static const Color background = Colors.white;
  static const Color text = Color(0xFF333333);
  static const Color lightText = Color(0xFF7A7A7A);
  static const Color accent = Color(0xFF3498DB);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
}

class AppTheme {
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 1.0],
    transform: GradientRotation(1.5708), // 90 degrees in radians
  );
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryStart,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'GlacialIndifference',
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'GlacialIndifference',
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryStart,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryStart,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[100],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.lightText),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.text,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.lightText,
        ),
      ),
    );
  }
}