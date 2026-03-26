import 'dart:async';

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

  /// connId for which a fetch has successfully completed.
  String? _lastFetchedConnId;

  /// Prevents overlapping concurrent fetches.
  bool _fetchInProgress = false;

  /// Retry timer used when a fetch fails transiently.
  Timer? _retryTimer;

  AgentIdentityNotifier(this._ref) : super(AgentIdentity.defaultIdentity);

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Called from the widget layer when the gateway becomes (or stays) connected.
  /// Safe to call on every rebuild — no-ops if we already have a result for
  /// this connection or a fetch is already underway.
  void fetchIfNeeded(String? connId) {
    if (connId == null) return;
    if (connId == _lastFetchedConnId) return; // already succeeded
    if (_fetchInProgress) return; // in flight
    _retryTimer?.cancel();
    _retryTimer = null;
    _fetchInProgress = true;
    _fetch(connId);
  }

  Future<void> _fetch(String connId) async {
    try {
      final result = await _ref
          .read(gatewayProvider.notifier)
          .sendRequest('agent.identity.get', {});

      final agentId = result['agentId'] as String? ?? 'main';
      final name = result['name'] as String? ?? 'Assistant';
      final avatar = result['avatar'] as String? ?? 'A';
      final emoji = result['emoji'] as String?;

      // Mark success before updating state so any triggered rebuild sees the
      // connId already recorded and doesn't schedule a duplicate fetch.
      _lastFetchedConnId = connId;
      _fetchInProgress = false;

      state = AgentIdentity(
        agentId: agentId,
        name: name,
        avatar: avatar,
        emoji: emoji,
      );
      debugPrint('[Pincers] Agent identity: name=$name avatar=$avatar');
    } catch (e) {
      debugPrint('[Pincers] agent.identity.get failed: $e — retrying in 3s');
      _fetchInProgress = false;
      // Retry after a short delay; only if the connection is still the same.
      _retryTimer = Timer(const Duration(seconds: 3), () {
        _retryTimer = null;
        final currentConnId = _ref.read(gatewayProvider).hello?.connId;
        if (currentConnId == connId) fetchIfNeeded(connId);
      });
    }
  }
}

final agentIdentityProvider =
    StateNotifierProvider<AgentIdentityNotifier, AgentIdentity>((ref) {
  return AgentIdentityNotifier(ref);
});

