import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../providers/chat_provider.dart';

class ChatHeader extends ConsumerStatefulWidget {
  const ChatHeader({super.key});

  @override
  ConsumerState<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends ConsumerState<ChatHeader> {
  bool _editing = false;
  late TextEditingController _titleController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing(String currentTitle) {
    _titleController.text = currentTitle;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: currentTitle.length,
      );
    });
  }

  Future<void> _submitTitle(String threadId) async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty) {
      await ref.read(threadsProvider.notifier).updateTitle(threadId, newTitle);
    }
    setState(() => _editing = false);
  }

  Future<void> _clearMessages(String threadId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Clear messages?',
          style: AppTypography.threadTitle.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'All messages in this conversation will be deleted. The thread will remain.',
          style: AppTypography.timestamp.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(chatProvider.notifier).clearMessages(threadId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadId = ref.watch(selectedThreadIdProvider);
    if (threadId == null) return const SizedBox.shrink();

    final threads = ref.watch(threadsProvider);
    final thread = threads.where((t) => t.id == threadId).firstOrNull;
    if (thread == null) return const SizedBox.shrink();

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space16),
      child: Row(
        children: [
          Expanded(
            child: _editing
                ? TextField(
                    controller: _titleController,
                    focusNode: _focusNode,
                    style: AppTypography.threadTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _submitTitle(threadId),
                    onEditingComplete: () => _submitTitle(threadId),
                    textInputAction: TextInputAction.done,
                  )
                : GestureDetector(
                    onTap: () => _startEditing(thread.title),
                    child: Text(
                      thread.title,
                      style: AppTypography.threadTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (_editing) ...[
            IconButton(
              icon: const Icon(Icons.check, size: 18, color: AppColors.accent),
              onPressed: () => _submitTitle(threadId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Save title',
            ),
            const SizedBox(width: AppConstants.space8),
            IconButton(
              icon: const Icon(Icons.close, size: 18,
                  color: AppColors.textSecondary),
              onPressed: () => setState(() => _editing = false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Cancel',
            ),
          ] else ...[
            _VerboseToggleButton(),
            const SizedBox(width: AppConstants.space4),
            PopupMenuButton<_ChatMenuAction>(
              icon: const Icon(Icons.more_horiz,
                  size: 20, color: AppColors.textSecondary),
              color: AppColors.bgTertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                side: const BorderSide(color: AppColors.border),
              ),
              onSelected: (action) {
                switch (action) {
                  case _ChatMenuAction.rename:
                    _startEditing(thread.title);
                  case _ChatMenuAction.clear:
                    _clearMessages(threadId);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _ChatMenuAction.rename,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppConstants.space8),
                      Text('Rename',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _ChatMenuAction.clear,
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_outlined,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: AppConstants.space8),
                      Text('Clear messages',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _ChatMenuAction { rename, clear }

/// Icon button that toggles verbose tool-call display in the chat.
class _VerboseToggleButton extends ConsumerWidget {
  const _VerboseToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verboseOn = ref.watch(verboseModeProvider);
    return IconButton(
      icon: Icon(
        Icons.account_tree_outlined,
        size: 16,
        color: verboseOn ? AppColors.accent : AppColors.textMuted,
      ),
      onPressed: () =>
          ref.read(verboseModeProvider.notifier).state = !verboseOn,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: verboseOn ? 'Hide tool activity' : 'Show tool activity',
    );
  }
}
