import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accent
  static const Color primary = Color(0xFF0D9488); // Modern Vibrant Teal
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);
  
  static const Color accent = Color(0xFF6366F1); // Electric Indigo
  static const Color accentLight = Color(0xFF818CF8);
  static const Color cyanAccent = Color(0xFF06B6D4); // Cyber Cyan
  
  // Financial State Colors
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeGlow = Color(0xFF34D399);
  static const Color expense = Color(0xFFF43F5E); // Crimson Rose
  static const Color expenseGlow = Color(0xFFFB7185);
  
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF38BDF8); // Sky Blue
  
  // Dark Glass Surfaces & Canvas
  static const Color darkCanvas = Color(0xFF090D16); // Deep Obsidian Slate
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkCard = Color(0xFF131B2E);
  static const Color darkSurfaceAlt = Color(0xFF1E293B);
  
  // Glassmorphism Tokens (Dark)
  static const Color glassDarkBg = Color(0x1FFFFFFF); // 12% white translucent
  static const Color glassDarkBorder = Color(0x33FFFFFF); // 20% white highlight rim
  static const Color glassDarkCard = Color(0x241E293B); // Translucent slate
  static const Color glassDarkShadow = Color(0x40000000);
  
  // Glassmorphism Tokens (Light)
  static const Color lightCanvas = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color glassLightBg = Color(0xCCFFFFFF); // 80% white frosted
  static const Color glassLightBorder = Color(0x66FFFFFF); // 40% white
  static const Color glassLightShadow = Color(0x140F172A);
  
  // Typography
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Group Accent Colors
  static const List<Color> groupPalette = [
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
  ];
}
