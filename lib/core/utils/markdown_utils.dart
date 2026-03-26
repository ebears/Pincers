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

MarkdownStyleSheet buildUserMarkdownStyleSheet() {
  const textStyle = TextStyle(color: Colors.white);
  final base = AppTypography.chatMessage.merge(textStyle);
  return MarkdownStyleSheet(
    p: base,
    strong: base.copyWith(fontWeight: FontWeight.bold),
    em: base.copyWith(fontStyle: FontStyle.italic),
    h1: base.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
    h2: base.copyWith(fontSize: 19, fontWeight: FontWeight.bold),
    h3: base.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
    code: AppTypography.codeBlock.copyWith(
      color: Colors.white,
      backgroundColor: Colors.white12,
    ),
    codeblockDecoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(8),
    ),
    blockquote: base.copyWith(color: Colors.white70),
    listBullet: base,
    a: base.copyWith(
      color: Colors.white,
      decoration: TextDecoration.underline,
      decorationColor: Colors.white70,
    ),
  );
}

Map<String, MarkdownElementBuilder> buildCodeBlockBuilders() {
  return {'code': CodeElementBuilder()};
}
