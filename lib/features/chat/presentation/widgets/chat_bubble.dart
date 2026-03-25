import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/utils/markdown_utils.dart';
import '../../data/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final DateTime? previousMessageTime;

  const ChatBubble({
    super.key,
    required this.message,
    this.previousMessageTime,
  });

  @override
  Widget build(BuildContext context) {
    final showTimestamp = TimeUtils.shouldShowTimestamp(previousMessageTime, message.createdAt);
    final isUser = message.isUser;
    final maxWidth = MediaQuery.of(context).size.width * AppConstants.bubbleMaxWidthFraction;

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
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _BubbleContent(message: message, isUser: isUser),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BubbleContent extends StatelessWidget {
  final MessageModel message;
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
          topRight: Radius.circular(isUser ? AppConstants.radiusSmall : AppConstants.radiusBubble),
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
            ),
    );
  }
}
