import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/agent_identity_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Circular avatar widget that renders an agent's avatar.
///
/// Handles three avatar forms returned by `agent.identity.get`:
/// - HTTP/HTTPS URL or data URL → [Image.network] with circular clip
/// - Gateway-relative path (e.g. `/avatar/main`) → resolved to HTTP URL then [Image.network]
/// - Short text / emoji → text centred in a coloured circle
class AgentAvatar extends ConsumerWidget {
  final double size;

  const AgentAvatar({super.key, this.size = 28});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(agentIdentityProvider);
    final gatewayUrl = ref.watch(authProvider).gatewayUrl;
    return _AvatarContent(
      identity: identity,
      gatewayUrl: gatewayUrl,
      size: size,
    );
  }
}

class _AvatarContent extends StatelessWidget {
  final AgentIdentity identity;
  final String? gatewayUrl;
  final double size;

  const _AvatarContent({
    required this.identity,
    required this.gatewayUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveAvatarUrl(identity.avatar, gatewayUrl);
    if (url != null) {
      return _ImageAvatar(url: url, size: size, fallbackLabel: _initials());
    }
    return _TextAvatar(label: _displayLabel(), size: size);
  }

  /// Text to display when the avatar is text/emoji.
  String _displayLabel() {
    final a = identity.avatar.trim();
    if (a.isNotEmpty) return a;
    return _initials();
  }

  /// Falls back to first letter of the agent name.
  String _initials() {
    final n = identity.name.trim();
    if (n.isEmpty) return 'A';
    return n.substring(0, 1).toUpperCase();
  }
}

class _ImageAvatar extends StatelessWidget {
  final String url;
  final double size;
  final String fallbackLabel;

  const _ImageAvatar({
    required this.url,
    required this.size,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _TextAvatar(label: fallbackLabel, size: size),
      ),
    );
  }
}

class _TextAvatar extends StatelessWidget {
  final String label;
  final double size;

  const _TextAvatar({required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    // Scale font relative to circle size.
    final fontSize = size * 0.42;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgElevated,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.0,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
