import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Stack(
      children: [
        GestureDetector(
          onTap: () => ref.read(settingsProvider.notifier).closePanel(),
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: AppConstants.settingsPanelWidth,
          child: Container(
            color: AppColors.bgSecondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.space16),
                  child: Row(
                    children: [
                      Text('Settings', style: AppTypography.emptyStateTitle.copyWith(fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => ref.read(settingsProvider.notifier).closePanel(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border),
                _Section(
                  title: 'Account',
                  children: [
                    _InfoRow(label: 'Gateway', value: auth.gatewayUrl ?? '—'),
                    const SizedBox(height: AppConstants.space8),
                    _InfoRow(
                      label: 'Token',
                      value: auth.token != null
                          ? '${auth.token!.substring(0, auth.token!.length.clamp(0, 8))}••••'
                          : '—',
                    ),
                    const SizedBox(height: AppConstants.space16),
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).clearCredentials();
                        ref.read(settingsProvider.notifier).closePanel();
                        if (context.mounted) context.go('/auth');
                      },
                      icon: const Icon(Icons.logout, size: 16, color: AppColors.error),
                      label: const Text('Sign out', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border),
                _Section(
                  title: 'About',
                  children: [
                    _InfoRow(label: 'App', value: 'Pincers v1.0.0'),
                    const SizedBox(height: AppConstants.space4),
                    _InfoRow(label: 'Agent', value: 'Aralobster 🦞'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTypography.sectionLabel),
          const SizedBox(height: AppConstants.space12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 60, child: Text(label, style: AppTypography.settingsLabel)),
        Expanded(child: Text(value, style: AppTypography.settingsValue)),
      ],
    );
  }
}
