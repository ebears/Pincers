import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class TokenEntryPage extends ConsumerStatefulWidget {
  const TokenEntryPage({super.key});

  @override
  ConsumerState<TokenEntryPage> createState() => _TokenEntryPageState();
}

class _TokenEntryPageState extends ConsumerState<TokenEntryPage> {
  final _urlController = TextEditingController(text: 'ws://');
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isConnecting = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).saveCredentials(
        _urlController.text.trim(),
        _tokenController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() { _error = 'Failed to connect: $e'; });
    } finally {
      if (mounted) setState(() { _isConnecting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.space32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('🦞', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
                  const SizedBox(height: AppConstants.space24),
                  Text(
                    'Connect to Aralobster',
                    style: AppTypography.emptyStateTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.space8),
                  Text(
                    'Enter your OpenClaw gateway URL and token.',
                    style: AppTypography.emptyStateBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.space32),
                  TextFormField(
                    controller: _urlController,
                    style: AppTypography.inputText,
                    decoration: const InputDecoration(hintText: 'Gateway URL (ws://...)'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.startsWith('ws://') && !v.startsWith('wss://')) {
                        return 'Must start with ws:// or wss://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.space16),
                  TextFormField(
                    controller: _tokenController,
                    obscureText: true,
                    style: AppTypography.inputText,
                    decoration: const InputDecoration(hintText: 'Bearer token'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppConstants.space12),
                    Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ],
                  const SizedBox(height: AppConstants.space24),
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _connect,
                    child: _isConnecting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
