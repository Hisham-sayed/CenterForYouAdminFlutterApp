import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0E14); // Deep Dark Blue/Black
  static const Color surface = Color(0xFF1A1F2C); // Slightly lighter for cards/sidebar
  static const Color surfaceHighlight = Color(0xFF2A2F3C); // Hover/Active states

  // Accents
  static const Color primary = Color(0xFF00E5FF); // Bright Cyan/Teal
  static const Color primaryDim = Color(0xFF00B8CC); // Dimmer primary for gradients/borders
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA); // Muted Grey
  
  // Status
  static const Color success = Color(0xFF10B981); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
