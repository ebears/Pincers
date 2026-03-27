import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/agent_identity_provider.dart';
import 'agent_avatar.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear messages?'),
        content: Text(
          'All messages in this conversation will be deleted. The thread will remain.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final threadId = ref.watch(selectedThreadIdProvider);
    if (threadId == null) return const SizedBox.shrink();

    final threads = ref.watch(threadsProvider);
    final thread = threads.where((t) => t.id == threadId).firstOrNull;
    if (thread == null) return const SizedBox.shrink();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.space16),
      child: Row(
        children: [
          Expanded(
            child: _editing
                ? TextField(
                    controller: _titleController,
                    focusNode: _focusNode,
                    style: textTheme.titleSmall,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _submitTitle(threadId),
                    onEditingComplete: () => _submitTitle(threadId),
                    textInputAction: TextInputAction.done,
                  )
                : Text(
                    thread.title,
                    style: textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (_editing) ...[
            IconButton(
              icon: Icon(Icons.check, size: 18, color: colorScheme.primary),
              onPressed: () => _submitTitle(threadId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Save title',
            ),
            const SizedBox(width: AppConstants.space8),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
              onPressed: () => setState(() => _editing = false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Cancel',
            ),
          ] else ...[
            _AgentIdentityBadge(),
            const SizedBox(width: AppConstants.space8),
            _VerboseToggleButton(),
            const SizedBox(width: AppConstants.space4),
            PopupMenuButton<_ChatMenuAction>(
              icon: Icon(Icons.more_horiz, size: 20, color: colorScheme.onSurfaceVariant),
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
                      Icon(Icons.edit_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppConstants.space8),
                      const Text('Rename'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _ChatMenuAction.clear,
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 16, color: colorScheme.error),
                      const SizedBox(width: AppConstants.space8),
                      Text('Clear messages', style: TextStyle(color: colorScheme.error)),
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

/// Shows agent avatar (20px) and name in the header.
class _AgentIdentityBadge extends ConsumerWidget {
  const _AgentIdentityBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final identity = ref.watch(agentIdentityProvider);
    final showName = identity.name != AgentIdentity.defaultIdentity.name ||
        identity.avatar != AgentIdentity.defaultIdentity.avatar;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgentAvatar(size: 20),
        if (showName) ...[
          const SizedBox(width: 6),
          Text(
            identity.name,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Icon button that toggles verbose tool-call display in the chat.
class _VerboseToggleButton extends ConsumerWidget {
  const _VerboseToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final verboseOn = ref.watch(verboseModeProvider);
    return IconButton(
      icon: Icon(
        Icons.account_tree,
        size: 16,
        color: verboseOn ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      onPressed: () =>
          ref.read(verboseModeProvider.notifier).state = !verboseOn,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: verboseOn ? 'Hide tool activity' : 'Show tool activity',
    );
  }
}
