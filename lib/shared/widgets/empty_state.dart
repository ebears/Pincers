import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../features/threads/presentation/providers/threads_provider.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';

class EmptyState extends ConsumerWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = [
      'Help me with a task',
      'Tell me something interesting',
      'Start a project',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🦞', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppConstants.space24),
            Text("Hi, I'm Aralobster.", style: AppTypography.emptyStateTitle),
            const SizedBox(height: AppConstants.space12),
            Text(
              "I'm your personal assistant — here to help,\nchat, and maybe cause some cheerful chaos.",
              style: AppTypography.emptyStateBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              'What would you like to do?',
              style: AppTypography.emptyStateBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space32),
            ...prompts.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.space8),
              child: _PromptChip(
                label: p,
                onTap: () => _startWithPrompt(ref, p),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _startWithPrompt(WidgetRef ref, String prompt) async {
    final thread = await ref.read(threadsProvider.notifier).createThread();
    ref.read(selectedThreadIdProvider.notifier).state = thread.id;
    ref.read(chatProvider.notifier).loadMessages(thread.id);
    await ref.read(chatProvider.notifier).sendMessage(thread.id, prompt);
  }
}

class _PromptChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PromptChip({required this.label, required this.onTap});

  @override
  State<_PromptChip> createState() => _PromptChipState();
}

class _PromptChipState extends State<_PromptChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.space16,
            vertical: AppConstants.space8,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(widget.label, style: AppTypography.button),
        ),
      ),
    );
  }
}
