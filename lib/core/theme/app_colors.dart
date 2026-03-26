import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bgPrimary    = Color(0xFF0D0D0F);
  static const bgSecondary  = Color(0xFF161618);
  static const bgTertiary   = Color(0xFF1E1E21);
  static const bgElevated   = Color(0xFF242428);
  static const bgHover      = Color(0xFF262629);
  static const border       = Color(0xFF2A2A2D);
  static const borderSubtle = Color(0xFF1E1E22);

  // Text — secondary bumped for improved readability
  static const textPrimary   = Color(0xFFECEDEE);
  static const textSecondary = Color(0xFFA1A1A9);
  static const textMuted     = Color(0xFF5C5C63);

  static const accent      = Color(0xFF7C5CFF);
  static const accentHover = Color(0xFF9070FF);
  static const accentGlow  = Color(0x267C5CFF);

  // Message bubbles — bot bubble visually distinct from bgTertiary
  static const userBubble = Color(0xFF7C5CFF);
  static const botBubble  = Color(0xFF1E1E21);

  static const success = Color(0xFF34D399);
  static const error   = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const info    = Color(0xFF60A5FA);
  static const typing  = Color(0xFFA1A1A9);
  static const online  = Color(0xFF34D399);
}
