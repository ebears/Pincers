import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/typing_provider.dart';
import '../providers/gateway_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/message_model.dart';
import '../../data/models/attachment_model.dart';
import 'chat_bubble.dart';
import 'chat_header.dart';
import 'typing_indicator.dart';
import 'input_area.dart';

class ChatArea extends ConsumerStatefulWidget {
  const ChatArea({super.key});

  @override
  ConsumerState<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends ConsumerState<ChatArea> {
  final _scrollController = ScrollController();
  bool _hasError = false;
  bool _isDragOver = false;
  final Set<String> _newMessageIds = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(
      String content, List<AttachmentModel> attachments) async {
    final threadId = ref.read(selectedThreadIdProvider);
    if (threadId == null) return;

    setState(() => _hasError = false);
    try {
      await ref
          .read(chatProvider.notifier)
          .sendMessage(threadId, content, attachments: attachments);
      _scrollToBottom();
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedThreadIdProvider);
    final messages = ref.watch(chatProvider);
    final isTyping = ref.watch(typingProvider);
    final gatewayStatus = ref.watch(gatewayProvider).status;

    ref.listen<List<MessageModel>>(chatProvider, (prev, next) {
      _scrollToBottom();
      if (prev != null && next.length > prev.length) {
        setState(() {
          for (final m in next.skip(prev.length)) {
            _newMessageIds.add(m.id);
          }
        });
      } else {
        setState(() => _newMessageIds.clear());
      }
    });

    if (selectedId == null) {
      return const Column(
        children: [
          Expanded(child: EmptyState()),
        ],
      );
    }

    final isConnected = gatewayStatus == GatewayStatus.connected;
    final isReconnecting = gatewayStatus == GatewayStatus.reconnecting;
    final extraItems = isTyping ? 1 : (isReconnecting ? 1 : 0);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragOver = true),
      onDragExited: (_) => setState(() => _isDragOver = false),
      onDragDone: (detail) {
        setState(() => _isDragOver = false);
        ref.read(droppedFilesProvider.notifier).state = detail.files;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: _isDragOver
            ? BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(AppConstants.radiusButton),
              )
            : null,
        child: Column(
          children: [
            const ChatHeader(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.space24),
                itemCount: messages.length + extraItems,
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    if (isTyping) return _centeredWidget(const TypingIndicator());
                    if (isReconnecting) {
                      return _centeredWidget(const _ReconnectingIndicator());
                    }
                  }
                  final msg = messages[index];
                  final prev =
                      index > 0 ? messages[index - 1].createdAt : null;
                  final bubble =
                      ChatBubble(message: msg, previousMessageTime: prev);
                  final isNew = _newMessageIds.contains(msg.id);
                  return _centeredWidget(
                    isNew ? _AnimatedMessageEntry(child: bubble) : bubble,
                  );
                },
              ),
            ),
            if (_hasError)
              Container(
                color: AppColors.error.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.space16,
                  vertical: AppConstants.space8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: AppConstants.space8),
                    Expanded(
                      child: Text(
                        "Couldn't send. Tap to retry.",
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: AppColors.error),
                      onPressed: () => setState(() => _hasError = false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            InputArea(
              onSend: _sendMessage,
              enabled: isConnected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _centeredWidget(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.chatMaxWidth),
        child: child,
      ),
    );
  }
}

// ── Task 4: slide-in animation for new messages ──────────────────────────────

class _AnimatedMessageEntry extends StatefulWidget {
  final Widget child;
  const _AnimatedMessageEntry({required this.child});

  @override
  State<_AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          Duration(milliseconds: AppConstants.messageAppearMs),
      vsync: this,
    );
    _opacity = _controller;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

// ── Task 3: reconnecting indicator ───────────────────────────────────────────

class _ReconnectingIndicator extends StatelessWidget {
  const _ReconnectingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.space16, vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.space16,
                vertical: AppConstants.space12),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusBubble),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppConstants.space8),
                Text(
                  'Reconnecting...',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
