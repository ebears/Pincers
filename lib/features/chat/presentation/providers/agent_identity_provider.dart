import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gateway_provider.dart';

/// Identity of the agent as returned by `agent.identity.get`.
class AgentIdentity {
  final String agentId;
  final String name;

  /// Raw avatar value from the gateway: may be a short string, emoji,
  /// HTTP URL, data URL, or a gateway-relative path like `/avatar/main`.
  final String avatar;
  final String? emoji;

  const AgentIdentity({
    required this.agentId,
    required this.name,
    required this.avatar,
    this.emoji,
  });

  static const defaultIdentity = AgentIdentity(
    agentId: 'main',
    name: 'Assistant',
    avatar: 'A',
  );
}

/// Resolves an avatar value to a URL string suitable for [Image.network],
/// or null if the avatar should be rendered as text.
///
/// Handles:
/// - HTTP/HTTPS absolute URLs → returned as-is
/// - `data:image/...` data URLs → returned as-is
/// - `/avatar/<id>` gateway-relative paths → resolved against the gateway HTTP base URL
/// - Short text / emoji → returns null (caller renders as text)
String? resolveAvatarUrl(String avatar, String? gatewayWsUrl) {
  final trimmed = avatar.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('data:image/')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    // Gateway-relative path — resolve against the HTTP base of the WS URL.
    if (gatewayWsUrl == null) return null;
    final httpBase = _wsUrlToHttpBase(gatewayWsUrl);
    if (httpBase == null) return null;
    return '$httpBase$trimmed';
  }
  return null;
}

String? _wsUrlToHttpBase(String wsUrl) {
  try {
    final uri = Uri.parse(wsUrl);
    final scheme = uri.scheme == 'wss' ? 'https' : 'http';
    return Uri(scheme: scheme, host: uri.host, port: uri.port).toString();
  } catch (_) {
    return null;
  }
}

class AgentIdentityNotifier extends StateNotifier<AgentIdentity> {
  final Ref _ref;

  /// Tracks the last connId we fetched for, to avoid redundant fetches.
  String? _lastFetchedConnId;

  AgentIdentityNotifier(this._ref) : super(AgentIdentity.defaultIdentity) {
    // Fetch on first build if already connected.
    _maybeFetch(_ref.read(gatewayProvider));
  }

  void onGatewayState(GatewayState gatewayState) {
    _maybeFetch(gatewayState);
  }

  Future<void> _maybeFetch(GatewayState gatewayState) async {
    if (gatewayState.status != GatewayStatus.connected) return;
    final connId = gatewayState.hello?.connId;
    if (connId == null || connId == _lastFetchedConnId) return;
    _lastFetchedConnId = connId;
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final result = await _ref
          .read(gatewayProvider.notifier)
          .sendRequest('agent.identity.get', {});

      final agentId = result['agentId'] as String? ?? 'main';
      final name = result['name'] as String? ?? 'Assistant';
      final avatar = result['avatar'] as String? ?? 'A';
      final emoji = result['emoji'] as String?;

      state = AgentIdentity(
        agentId: agentId,
        name: name,
        avatar: avatar,
        emoji: emoji,
      );
      debugPrint('[Pincers] Agent identity: name=$name avatar=$avatar');
    } catch (e) {
      debugPrint('[Pincers] agent.identity.get failed (non-fatal): $e');
      // Keep whatever state we have (default or previously fetched).
    }
  }
}

final agentIdentityProvider =
    StateNotifierProvider<AgentIdentityNotifier, AgentIdentity>((ref) {
  final notifier = AgentIdentityNotifier(ref);
  // Re-fetch whenever the gateway state changes (handles reconnect).
  ref.listen<GatewayState>(gatewayProvider, (_, next) {
    notifier.onGatewayState(next);
  });
  return notifier;
});
