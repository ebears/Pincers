import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Domain-specific text styles not covered by the M3 TextTheme.
///
/// For structural UI text (titles, labels, body copy), use
/// Theme.of(context).textTheme instead.
class AppTypography {
  AppTypography._();

  /// Chat message body — 15sp Inter, line-height 1.6.
  static TextStyle get chatMessage => GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  /// Timestamp label shown between messages — 12sp Inter.
  static TextStyle get timestamp => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  /// Input field text — 15sp Inter.
  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textPrimary,
      );

  /// Monospace — JetBrains Mono 13sp, used only for code blocks.
  static TextStyle get codeBlock => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: AppColors.textPrimary,
      );
}
