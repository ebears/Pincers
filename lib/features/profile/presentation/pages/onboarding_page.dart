import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gatewayUrlController = TextEditingController(text: 'wss://');
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _gatewayUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).validateAndSaveCredentials(
        _gatewayUrlController.text.trim(),
        _tokenController.text.trim(),
      );
      await ref.read(userProfileProvider.notifier).save(_nameController.text.trim());
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _messageForFailure(e.reason);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  String _messageForFailure(AuthFailureReason reason) {
    switch (reason) {
      case AuthFailureReason.timeout:
        return 'Gateway didn\'t respond. Check the URL and try again.';
      case AuthFailureReason.networkError:
        return 'Couldn\'t reach the gateway. Check your connection and URL.';
      case AuthFailureReason.authRejected:
        return 'Token rejected. Double-check your bearer token.';
      case AuthFailureReason.generic:
        return 'Connection failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.space32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('👋', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
                  const SizedBox(height: AppConstants.space24),
                  Text(
                    'Welcome to Pincers',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.space8),
                  Text(
                    'Enter your details to get started',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.space32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Display Name'),
                    maxLength: 50,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppConstants.space16),
                  TextFormField(
                    controller: _gatewayUrlController,
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
                    decoration: const InputDecoration(hintText: 'Bearer Token'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppConstants.space12),
                    Text(
                      _errorMessage!,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: AppConstants.space24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
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
