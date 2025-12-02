import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFFF59E0B); // Amber
  static const Color accent = Color(0xFF10B981); // Green
  
  // Background colors
  static const Color background = Color(0xFFFFFBEB); // Light yellow
  static const Color surface = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  
  // Status colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue
  
  // Border and shadow
  static const Color border = Color(0xFF000000); // Black
  static const Color shadow = Color(0xFF000000); // Black
  
  // Difficulty colors
  static const Color easy = Color(0xFF10B981); // Green
  static const Color medium = Color(0xFFF59E0B); // Amber
  static const Color hard = Color(0xFFEF4444); // Red
  
  // Priority colors
  static const Color highPriority = Color(0xFFEF4444); // Red
  static const Color mediumPriority = Color(0xFFF59E0B); // Amber
  static const Color lowPriority = Color(0xFF10B981); // Green
  
  // Mode colors
  static const Color solo = Color(0xFF8B5CF6); // Purple
  static const Color team = Color(0xFF3B82F6); // Blue
  
  // Role colors (Neobrutalism style - bold and vibrant)
  static const Color roleFrontend = Color(0xFF06B6D4); // Cyan - for UI/Frontend
  static const Color roleBackend = Color(0xFF8B5CF6); // Purple - for Backend
  static const Color roleUiux = Color(0xFFEC4899); // Pink - for UI/UX Design
  static const Color rolePm = Color(0xFFF59E0B); // Amber - for Project Manager
  static const Color roleFullstack = Color(0xFF10B981); // Green - for Fullstack
  
  // Helper method to get role color
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'frontend':
        return roleFrontend;
      case 'backend':
        return roleBackend;
      case 'uiux':
        return roleUiux;
      case 'pm':
        return rolePm;
      case 'fullstack':
        return roleFullstack;
      default:
        return primary;
    }
  }
}
