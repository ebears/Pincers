import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/time_utils.dart';
import '../../data/models/thread_model.dart';
import '../providers/threads_provider.dart';

class ThreadItem extends ConsumerStatefulWidget {
  final ThreadModel thread;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int staggerIndex;

  const ThreadItem({
    super.key,
    required this.thread,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    this.staggerIndex = 0,
  });

  @override
  ConsumerState<ThreadItem> createState() => _ThreadItemState();
}

class _ThreadItemState extends ConsumerState<ThreadItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _opacity = _controller;
    Future<void>.delayed(
      Duration(milliseconds: widget.staggerIndex * AppConstants.threadStaggerMs),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewlyCreated = ref.watch(newlyCreatedThreadIdProvider) == widget.thread.id;

    return FadeTransition(
      opacity: _opacity,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: isNewlyCreated
                  ? AppColors.accentGlow
                  : widget.isSelected
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
                      if (widget.thread.preview != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          widget.thread.preview!,
                          style: AppTypography.threadSubtitle.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
      ),
    );
  }
}
