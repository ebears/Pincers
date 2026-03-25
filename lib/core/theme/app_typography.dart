import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

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
        letterSpacing: 0.05 * 12,
      );

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

  static TextStyle get codeBlock => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: AppColors.textPrimary,
      );

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
