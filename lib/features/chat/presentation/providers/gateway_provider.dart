import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/websocket_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum GatewayStatus { disconnected, connecting, connected, error }

class GatewayState {
  final GatewayStatus status;
  final String? errorMessage;

  const GatewayState({
    this.status = GatewayStatus.disconnected,
    this.errorMessage,
  });
}

class GatewayNotifier extends StateNotifier<GatewayState> {
  final WebSocketService _ws;
  final Ref _ref;

  GatewayNotifier(this._ws, this._ref) : super(const GatewayState());

  Stream<Map<String, dynamic>>? get messages => _ws.messages;

  Future<void> connect() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    state = const GatewayState(status: GatewayStatus.connecting);
    try {
      await _ws.connect(auth.gatewayUrl!, auth.token!);
      state = const GatewayState(status: GatewayStatus.connected);
    } catch (e) {
      state = GatewayState(status: GatewayStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> send(String method, Map<String, dynamic> params, {String? id}) async {
    await _ws.send(method, params, id: id);
  }

  void disconnect() {
    _ws.disconnect();
    state = const GatewayState(status: GatewayStatus.disconnected);
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

final gatewayProvider = StateNotifierProvider<GatewayNotifier, GatewayState>((ref) {
  return GatewayNotifier(
    ref.watch(webSocketServiceProvider),
    ref,
  );
});
