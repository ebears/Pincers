import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/device_identity_service.dart';
import '../../../../shared/services/websocket_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum GatewayStatus { disconnected, connecting, connected, reconnecting, error }

class GatewayState {
  final GatewayStatus status;
  final String? errorMessage;
  final HelloResult? hello;

  const GatewayState({
    this.status = GatewayStatus.disconnected,
    this.errorMessage,
    this.hello,
  });
}

class GatewayNotifier extends StateNotifier<GatewayState> {
  final WebSocketService _ws;
  final DeviceIdentityService _deviceIdentity;
  final Ref _ref;

  GatewayNotifier(this._ws, this._deviceIdentity, this._ref)
      : super(const GatewayState()) {
    _ws.onStatusChange = _onWsStatusChange;
  }

  void _onWsStatusChange(ConnectionStatus cs) {
    if (!mounted) return;
    switch (cs) {
      case ConnectionStatus.reconnecting:
        state = GatewayState(
            status: GatewayStatus.reconnecting, hello: state.hello);
      case ConnectionStatus.connected:
        state = GatewayState(
            status: GatewayStatus.connected, hello: state.hello);
      case ConnectionStatus.disconnected:
        state = const GatewayState(status: GatewayStatus.disconnected);
      case ConnectionStatus.error:
        state = GatewayState(
            status: GatewayStatus.error, hello: state.hello);
      case ConnectionStatus.connecting:
        state = GatewayState(
            status: GatewayStatus.connecting, hello: state.hello);
    }
  }

  /// Stream of gateway event frames (chat, tick, etc.).
  Stream<Map<String, dynamic>> get events => _ws.events;

  /// Wait for the gateway to reach connected state, triggering a connect
  /// attempt if currently disconnected or in error state.
  Future<void> waitForConnection({Duration timeout = const Duration(seconds: 15)}) async {
    if (state.status == GatewayStatus.connected) return;

    // Trigger a connect attempt if not already connecting/reconnecting.
    if (state.status == GatewayStatus.disconnected ||
        state.status == GatewayStatus.error) {
      // Don't await — we listen for state changes below.
      unawaited(connect());
    }

    final completer = Completer<void>();
    void listener(GatewayState s) {
      if (completer.isCompleted) return;
      if (s.status == GatewayStatus.connected) {
        completer.complete();
      }
      // Only fail on error/disconnected if we're not about to retry.
      // The WS service handles its own reconnection, so error here is terminal.
      else if (s.status == GatewayStatus.error) {
        completer.completeError(
            StateError(s.errorMessage ?? 'Gateway connection failed'));
      }
    }

    final removeListener = addListener(listener);
    try {
      await completer.future.timeout(timeout, onTimeout: () {
        throw TimeoutException('Timed out waiting for gateway connection');
      });
    } finally {
      removeListener();
    }
  }

  Future<void> connect() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) {
      debugPrint('[Pincers] Gateway connect skipped: not authenticated');
      return;
    }

    debugPrint('[Pincers] Gateway connecting to ${auth.gatewayUrl}...');
    state = const GatewayState(status: GatewayStatus.connecting);
    try {
      await _deviceIdentity.ensureInitialized();
      debugPrint('[Pincers] Device identity ready (id: ${_deviceIdentity.deviceId})');
      final gatewayUrl = auth.gatewayUrl;
      final token = auth.token;
      if (gatewayUrl == null || token == null) {
        throw StateError('gatewayUrl or token is null despite isAuthenticated=true');
      }
      final hello = await _ws.connect(
        gatewayUrl,
        token,
        deviceIdentity: _deviceIdentity,
      );
      debugPrint('[Pincers] Gateway connected (connId: ${hello.connId})');
      state = GatewayState(status: GatewayStatus.connected, hello: hello);
    } catch (e) {
      debugPrint('[Pincers] Gateway connect failed: $e');
      state = GatewayState(
          status: GatewayStatus.error, errorMessage: e.toString());
    }
  }

  /// Send a request and await the response payload.
  Future<Map<String, dynamic>> sendRequest(
      String method, Map<String, dynamic> params) {
    return _ws.sendRequest(method, params);
  }

  void disconnect() {
    _ws.disconnect();
    state = const GatewayState(status: GatewayStatus.disconnected);
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

final deviceIdentityProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

final gatewayProvider =
    StateNotifierProvider<GatewayNotifier, GatewayState>((ref) {
  return GatewayNotifier(
    ref.watch(webSocketServiceProvider),
    ref.watch(deviceIdentityProvider),
    ref,
  );
});
