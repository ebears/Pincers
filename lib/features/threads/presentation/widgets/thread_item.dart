import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isNewlyCreated =
        ref.watch(newlyCreatedThreadIdProvider) == widget.thread.id;

    final backgroundColor = isNewlyCreated
        ? colorScheme.primaryContainer.withValues(alpha: 0.15)
        : widget.isSelected
            ? colorScheme.surfaceContainer
            : Colors.transparent;

    return FadeTransition(
      opacity: _opacity,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (hovered) => setState(() => _hovered = hovered),
          mouseCursor: SystemMouseCursors.click,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
            }
            return Colors.transparent;
          }),
          child: Container(
            decoration: widget.isSelected
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: colorScheme.primary, width: 3),
                    ),
                  )
                : null,
            padding: EdgeInsets.only(
              left: widget.isSelected
                  ? AppConstants.space16 - 3
                  : AppConstants.space16,
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
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.thread.preview != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          widget.thread.preview!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        TimeUtils.formatThreadTime(widget.thread.updatedAt),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
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
