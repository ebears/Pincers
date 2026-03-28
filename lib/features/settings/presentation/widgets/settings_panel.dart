import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/agent_identity_provider.dart';
import '../../../chat/presentation/widgets/agent_avatar.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.space16,
            AppConstants.space16,
            AppConstants.space8,
            AppConstants.space16,
          ),
          child: Row(
            children: [
              Text(
                'Settings',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        Divider(color: colorScheme.outline, height: 1),
        _Section(
          title: 'ACCOUNT',
          children: [
            _InfoRow(label: 'Gateway', value: auth.gatewayUrl ?? '—'),
            const SizedBox(height: AppConstants.space8),
            _CopyableTokenRow(token: auth.token),
            const SizedBox(height: AppConstants.space8),
            const _DisplayNameRow(),
            const SizedBox(height: AppConstants.space16),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).clearCredentials();
                if (!context.mounted) return;
                context.pop();
                context.go('/auth');
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign out'),
            ),
          ],
        ),
        Divider(color: colorScheme.outline, height: 1),
        _Section(
          title: 'ABOUT',
          children: [
            _InfoRow(label: 'App', value: 'Pincers v1.0.0'),
            const SizedBox(height: AppConstants.space12),
            _AgentRow(),
          ],
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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
          ),
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: textTheme.bodyMedium)),
      ],
    );
  }
}

class _CopyableTokenRow extends StatefulWidget {
  final String? token;
  const _CopyableTokenRow({this.token});

  @override
  State<_CopyableTokenRow> createState() => _CopyableTokenRowState();
}

class _CopyableTokenRowState extends State<_CopyableTokenRow> {
  bool _copied = false;

  String get _masked {
    if (widget.token == null) return '—';
    final prefix = widget.token!.substring(0, widget.token!.length.clamp(0, 8));
    return '$prefix••••';
  }

  Future<void> _copy() async {
    if (widget.token == null) return;
    await Clipboard.setData(ClipboardData(text: widget.token!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            'Token',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(_masked, style: textTheme.bodyMedium)),
        if (widget.token != null)
          IconButton(
            onPressed: _copy,
            icon: Icon(
              _copied ? Icons.check : Icons.copy,
              size: 14,
              color: _copied ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            tooltip: _copied ? 'Copied!' : 'Copy token',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}

/// Displays the live agent identity (avatar + name) fetched from the gateway.
class _AgentRow extends ConsumerWidget {
  const _AgentRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final identity = ref.watch(agentIdentityProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            'Agent',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        AgentAvatar(size: 24),
        const SizedBox(width: AppConstants.space8),
        Expanded(
          child: Text(identity.name, style: textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _DisplayNameRow extends ConsumerStatefulWidget {
  const _DisplayNameRow();

  @override
  ConsumerState<_DisplayNameRow> createState() => _DisplayNameRowState();
}

class _DisplayNameRowState extends ConsumerState<_DisplayNameRow> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    final name = ref.read(userProfileProvider).name;
    _controller.text = name ?? '';
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _save() async {
    final notifier = ref.read(userProfileProvider.notifier);
    if (notifier.hasProfile) {
      await notifier.updateName(_controller.text);
    } else {
      await notifier.save(_controller.text);
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final name = profile.name;

    if (_isEditing) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Name',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.space8,
                  vertical: AppConstants.space4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(width: AppConstants.space8),
          IconButton(
            onPressed: _save,
            icon: Icon(Icons.check, size: 16, color: colorScheme.primary),
            tooltip: 'Save',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: AppConstants.space8),
          IconButton(
            onPressed: _cancelEditing,
            icon: Icon(Icons.close, size: 16, color: colorScheme.onSurfaceVariant),
            tooltip: 'Cancel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            'Name',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            name ?? 'Not set',
            style: textTheme.bodyMedium?.copyWith(
              color: name == null ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        IconButton(
          onPressed: _startEditing,
          icon: Icon(Icons.edit, size: 14, color: colorScheme.onSurfaceVariant),
          tooltip: 'Edit',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
