import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Named semantic text styles for Pincers UI components.
///
/// M3 type scale mapping (for reference):
///   emptyStateTitle  → titleLarge
///   threadTitle      → titleSmall / labelLarge
///   chatMessage      → bodyMedium (15 sp)
///   inputText        → bodyMedium
///   button           → labelLarge
///   timestamp        → labelSmall
///   threadSubtitle   → bodySmall
///   sectionLabel     → labelSmall (uppercase)
///   settingsLabel    → bodyMedium (muted)
///   settingsValue    → bodyMedium
///   codeBlock        → (monospace, outside Inter scale)
class AppTypography {
  AppTypography._();

  static TextStyle get chatMessage => GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get timestamp => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get threadTitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get threadSubtitle => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      );

  /// M3 titleLarge equivalent used for page/panel headings.
  static TextStyle get emptyStateTitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get emptyStateBody => GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  /// Monospace — outside the Inter scale, used only for code blocks.
  static TextStyle get codeBlock => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: AppColors.textPrimary,
      );

  /// M3 labelLarge — primary button and action labels.
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get settingsLabel => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get settingsValue => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textPrimary,
      );
}
