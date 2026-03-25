import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/time_utils.dart';
import '../../data/models/thread_model.dart';

class ThreadItem extends StatefulWidget {
  final ThreadModel thread;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ThreadItem({
    super.key,
    required this.thread,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<ThreadItem> createState() => _ThreadItemState();
}

class _ThreadItemState extends State<ThreadItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.bgTertiary
                : _hovered
                    ? AppColors.bgHover
                    : Colors.transparent,
            border: widget.isSelected
                ? const Border(left: BorderSide(color: AppColors.accent, width: 3))
                : null,
          ),
          padding: EdgeInsets.only(
            left: widget.isSelected ? AppConstants.space16 - 3 : AppConstants.space16,
            right: AppConstants.space8,
            top: AppConstants.space8,
            bottom: AppConstants.space8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.thread.title,
                      style: AppTypography.threadTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TimeUtils.formatThreadTime(widget.thread.updatedAt),
                      style: AppTypography.threadSubtitle,
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete conversation',
                  padding: const EdgeInsets.all(AppConstants.space8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
