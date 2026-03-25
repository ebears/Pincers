import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';

class ThreadGroupHeader extends StatelessWidget {
  final String label;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const ThreadGroupHeader({
    super.key,
    required this.label,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.space16,
          vertical: AppConstants.space8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.sectionLabel,
              ),
            ),
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
