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
import 'verbose_bubble.dart';

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

  // Store last failed send for retry.
  String? _lastFailedContent;
  List<AttachmentModel> _lastFailedAttachments = const [];

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

    setState(() {
      _hasError = false;
    });
    try {
      await ref
          .read(chatProvider.notifier)
          .sendMessage(threadId, content, attachments: attachments);
      _lastFailedContent = null;
      _lastFailedAttachments = const [];
      _scrollToBottom();
    } catch (e) {
      _lastFailedContent = content;
      _lastFailedAttachments = attachments;
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _retry() async {
    if (_lastFailedContent == null) return;
    // Remove the optimistically-added user message before resending.
    final threadId = ref.read(selectedThreadIdProvider);
    if (threadId == null) return;
    await _sendMessage(_lastFailedContent!, _lastFailedAttachments);
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedThreadIdProvider);
    final allMessages = ref.watch(chatProvider);
    final isTyping =
        selectedId != null && ref.watch(typingProvider(selectedId));
    final gatewayStatus = ref.watch(gatewayProvider).status;
    final verboseMode = ref.watch(verboseModeProvider);

    // Only show messages belonging to the active thread.
    final threadMessages = selectedId == null
        ? const <MessageModel>[]
        : allMessages.where((m) => m.threadId == selectedId).toList();

    // Only show verbose entries when the toggle is on.
    final displayMessages = verboseMode
        ? threadMessages
        : threadMessages.where((m) => !m.isVerbose).toList();

    ref.listen<List<MessageModel>>(chatProvider, (prev, next) {
      if (selectedId == null) return;
      final prevFiltered =
          prev?.where((m) => m.threadId == selectedId).toList() ?? [];
      final nextFiltered =
          next.where((m) => m.threadId == selectedId).toList();
      if (nextFiltered.length > prevFiltered.length) {
        _scrollToBottom();
        setState(() {
          for (final m in nextFiltered.skip(prevFiltered.length)) {
            _newMessageIds.add(m.id);
          }
        });
      }
    });

    // Clear animation set when the user switches threads.
    ref.listen<String?>(selectedThreadIdProvider, (prev, next) {
      if (prev != next) setState(() => _newMessageIds.clear());
    });

    if (selectedId == null) {
      return const Column(
        children: [
          Expanded(child: EmptyState()),
        ],
      );
    }

    final isConnecting = gatewayStatus == GatewayStatus.connecting;
    final isReconnecting = gatewayStatus == GatewayStatus.reconnecting;
    final showStatusIndicator = isTyping || isReconnecting || isConnecting;
    final extraItems = showStatusIndicator ? 1 : 0;

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
              child: SelectionArea(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.space24),
                itemCount: displayMessages.length + extraItems,
                itemBuilder: (context, index) {
                  if (index == displayMessages.length) {
                    if (isTyping) return _centeredWidget(const TypingIndicator());
                    if (isReconnecting || isConnecting) {
                      return _centeredWidget(_ReconnectingIndicator(
                        message: isConnecting ? 'Connecting...' : 'Reconnecting...',
                      ));
                    }
                  }
                  final msg = displayMessages[index];
                  final prev =
                      index > 0 ? displayMessages[index - 1].createdAt : null;
                  final Widget bubbleWidget = msg.isVerbose
                      ? VerboseBubble(message: msg)
                      : ChatBubble(message: msg, previousMessageTime: prev);
                  final isNew = _newMessageIds.contains(msg.id);
                  return _centeredWidget(
                    isNew ? _AnimatedMessageEntry(child: bubbleWidget) : bubbleWidget,
                  );
                },
              ),
              ),
            ),
            if (_hasError)
              InkWell(
                onTap: _retry,
                child: Container(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.space16,
                    vertical: AppConstants.space8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: AppConstants.space8),
                      Expanded(
                        child: Text(
                          "Couldn't send. Click to retry.",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => setState(() => _hasError = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            InputArea(
              onSend: _sendMessage,
              enabled: true,
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
  final String message;
  const _ReconnectingIndicator({this.message = 'Reconnecting...'});

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
                  message,
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
