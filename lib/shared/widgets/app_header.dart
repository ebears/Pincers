import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

class AppHeader extends ConsumerWidget {
  final bool showMenuButton;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    this.showMenuButton = false,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppConstants.headerHeight,
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space16),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (showMenuButton) const SizedBox(width: AppConstants.space12),
          const Text('🦞', style: TextStyle(fontSize: 20)),
          const SizedBox(width: AppConstants.space8),
          Text(
            'Pincers',
            style: AppTypography.threadTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textSecondary),
            onPressed: () => ref.read(settingsProvider.notifier).togglePanel(),
            tooltip: 'Settings',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

