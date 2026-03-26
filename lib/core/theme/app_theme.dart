import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      // Core brand
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF3D2E8A),
      onPrimaryContainer: Color(0xFFD4CAFF),

      // Secondary (accent hover)
      secondary: AppColors.accentHover,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF2D2060),
      onSecondaryContainer: Color(0xFFE0D8FF),

      // Tertiary (info blue)
      tertiary: AppColors.info,
      onTertiary: Color(0xFF003060),
      tertiaryContainer: Color(0xFF004680),
      onTertiaryContainer: Color(0xFFCDE5FF),

      // Error
      error: AppColors.error,
      onError: Color(0xFF4A0000),
      errorContainer: Color(0xFF5C1A1A),
      onErrorContainer: Color(0xFFFFDAD6),

      // Surfaces — map to the app's bg layer hierarchy
      surface: AppColors.bgPrimary,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceDim: Color(0xFF080809),
      surfaceBright: AppColors.bgElevated,
      surfaceContainerLowest: AppColors.bgPrimary,
      surfaceContainerLow: AppColors.bgSecondary,
      surfaceContainer: AppColors.bgTertiary,
      surfaceContainerHigh: AppColors.bgElevated,
      surfaceContainerHighest: AppColors.bgHover,

      // Outline / dividers
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,

      // Inverse
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.bgPrimary,
      inversePrimary: AppColors.accent,

      // Overlay
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: AppColors.accent,
    );

    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge:  const TextStyle(color: AppColors.textPrimary),
      displayMedium: const TextStyle(color: AppColors.textPrimary),
      displaySmall:  const TextStyle(color: AppColors.textPrimary),
      headlineLarge:  const TextStyle(color: AppColors.textPrimary),
      headlineMedium: const TextStyle(color: AppColors.textPrimary),
      headlineSmall:  const TextStyle(color: AppColors.textPrimary),
      titleLarge:  const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      titleSmall:  const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      bodyLarge:  const TextStyle(color: AppColors.textPrimary),
      bodyMedium: const TextStyle(color: AppColors.textPrimary),
      bodySmall:  const TextStyle(color: AppColors.textSecondary),
      labelLarge:  const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      labelMedium: const TextStyle(color: AppColors.textSecondary),
      labelSmall:  const TextStyle(color: AppColors.textSecondary),
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: colorScheme,
      textTheme: textTheme,
      useMaterial3: true,

      // ── Divider ───────────────────────────────────────────────────────────
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),

      // ── Icons ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textSecondary),

      // ── AppBar ────────────────────────────────────────────────────────────
      // surfaceContainerLow keeps it visually distinct from the page surface
      // while staying within M3's "top app bar" colour recommendation.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: textTheme.titleMedium,
      ),

      // ── Input decoration ──────────────────────────────────────────────────
      // M3 filled text field: filled=true, no explicit border on enabled state,
      // accent border when focused.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        errorStyle: const TextStyle(color: AppColors.error),
      ),

      // ── Buttons ───────────────────────────────────────────────────────────
      // FilledButton is the M3 primary-emphasis button.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bgHover,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // ElevatedButton used only for secondary / tonal actions in M3.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgElevated,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ── IconButton ────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          highlightColor: AppColors.bgHover,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.bgTertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── List tiles ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.bgTertiary,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        selectedColor: AppColors.accent,
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgTertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodySmall?.copyWith(fontSize: 13),
      ),

      // ── Popup menu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.bgTertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(fontSize: 14),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(fontSize: 14) ?? const TextStyle(fontSize: 14),
        ),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgTertiary,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgTertiary,
        selectedColor: AppColors.accentGlow,
        disabledColor: AppColors.bgHover,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusButton)),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.accent),
        iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 16),
        deleteIconColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Navigation drawer ─────────────────────────────────────────────────
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accentGlow,
        elevation: 0,
      ),
    );
  }
}

