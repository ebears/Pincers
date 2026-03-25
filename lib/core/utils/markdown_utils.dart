import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/chat/presentation/widgets/code_block_widget.dart';

MarkdownStyleSheet buildMarkdownStyleSheet() {
  return MarkdownStyleSheet(
    p: AppTypography.chatMessage,
    strong: AppTypography.chatMessage.copyWith(fontWeight: FontWeight.bold),
    em: AppTypography.chatMessage.copyWith(fontStyle: FontStyle.italic),
    code: AppTypography.codeBlock.copyWith(
      backgroundColor: AppColors.bgPrimary,
    ),
    codeblockDecoration: BoxDecoration(
      color: AppColors.bgPrimary,
      borderRadius: BorderRadius.circular(8),
    ),
    blockquote: AppTypography.chatMessage.copyWith(color: AppColors.textSecondary),
    listBullet: AppTypography.chatMessage,
    a: AppTypography.chatMessage.copyWith(
      color: AppColors.accent,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.accent,
    ),
  );
}

Map<String, MarkdownElementBuilder> buildCodeBlockBuilders() {
  return {'code': CodeElementBuilder()};
}
