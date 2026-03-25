import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/typing_provider.dart';
import '../providers/gateway_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import 'chat_bubble.dart';
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

  Future<void> _sendMessage(String content) async {
    final threadId = ref.read(selectedThreadIdProvider);
    if (threadId == null) return;

    setState(() => _hasError = false);
    try {
      await ref.read(chatProvider.notifier).sendMessage(threadId, content);
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

    ref.listen(chatProvider, (prev, next) => _scrollToBottom());

    if (selectedId == null) {
      return const Column(
        children: [
          Expanded(child: EmptyState()),
        ],
      );
    }

    final isConnected = gatewayStatus == GatewayStatus.connected;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: AppConstants.space24),
            itemCount: messages.length + (isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (isTyping && index == messages.length) {
                return _centeredWidget(const TypingIndicator());
              }
              final msg = messages[index];
              final prev = index > 0 ? messages[index - 1].createdAt : null;
              return _centeredWidget(
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: AppConstants.messageAppearMs),
                  child: ChatBubble(message: msg, previousMessageTime: prev),
                ),
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
                const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                const SizedBox(width: AppConstants.space8),
                Expanded(
                  child: Text(
                    "Couldn't send. Tap to retry.",
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.error),
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
    );
  }

  Widget _centeredWidget(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.chatMaxWidth),
        child: child,
      ),
    );
  }
}
