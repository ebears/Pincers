import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/utils/markdown_utils.dart';
import '../../data/models/message_model.dart';
import 'agent_avatar.dart';

class ChatBubble extends ConsumerWidget {
  final MessageModel message;
  final DateTime? previousMessageTime;

  const ChatBubble({
    super.key,
    required this.message,
    this.previousMessageTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTimestamp = TimeUtils.shouldShowTimestamp(previousMessageTime, message.createdAt);
    final isUser = message.isUser;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.space8),
            child: Center(
              child: Text(
                TimeUtils.formatMessageTime(message.createdAt),
                style: AppTypography.timestamp,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.space16,
            vertical: 3,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth *
                  (isUser
                      ? AppConstants.bubbleMaxWidthFraction
                      : AppConstants.botBubbleMaxWidthFraction);
              if (isUser) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _BubbleContent(message: message, isUser: true),
                    ),
                  ],
                );
              }
              // Bot message: avatar to the left.
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: AppConstants.space8),
                    child: AgentAvatar(size: 28),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: maxWidth - 28 - AppConstants.space8),
                    child: _BubbleContent(message: message, isUser: false),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BubbleContent extends StatelessWidget {  final MessageModel message;
  final bool isUser;

  const _BubbleContent({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space16,
        vertical: AppConstants.space12,
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.userBubble : AppColors.botBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppConstants.radiusBubble),
          topRight: const Radius.circular(AppConstants.radiusBubble),
          bottomLeft: Radius.circular(isUser ? AppConstants.radiusBubble : AppConstants.radiusSmall),
          bottomRight: const Radius.circular(AppConstants.radiusBubble),
        ),
        border: isUser ? null : Border.all(color: AppColors.border),
      ),
      child: isUser
          ? Text(message.content, style: AppTypography.chatMessage.copyWith(color: Colors.white))
          : MarkdownBody(
              data: message.content,
              styleSheet: buildMarkdownStyleSheet(),
              builders: buildCodeBlockBuilders(),
              selectable: true,
              sizedImageBuilder: (MarkdownImageConfig config) => _TappableImage(uri: config.uri),
            ),
    );
  }
}

class _TappableImage extends StatelessWidget {
  final Uri uri;
  const _TappableImage({required this.uri});

  void _showLightbox(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: Image.network(uri.toString()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLightbox(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          uri.toString(),
          errorBuilder: (_, _, _) => const Icon(
            Icons.broken_image,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
