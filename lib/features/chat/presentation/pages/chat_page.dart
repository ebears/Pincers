import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../threads/presentation/widgets/thread_list.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../../../settings/presentation/widgets/settings_panel.dart';
import '../../../../shared/widgets/app_header.dart';
import '../providers/chat_provider.dart';
import '../providers/gateway_provider.dart';
import '../providers/agent_identity_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/chat_area.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _ensureGatewayConnected() {
    final auth = ref.read(authProvider);
    if (auth.isLoading || !auth.isAuthenticated) return;
    final status = ref.read(gatewayProvider).status;
    if (status == GatewayStatus.disconnected || status == GatewayStatus.error) {
      ref.read(gatewayProvider.notifier).connect();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Ctrl+N → new thread
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyN) {
      _newThread();
      return KeyEventResult.handled;
    }

    // Ctrl+W → deselect thread
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyW) {
      ref.read(selectedThreadIdProvider.notifier).state = null;
      return KeyEventResult.handled;
    }

    // Escape → close open drawers
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
        _scaffoldKey.currentState?.closeEndDrawer();
        return KeyEventResult.handled;
      }
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        _scaffoldKey.currentState?.closeDrawer();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  Future<void> _newThread() async {
    final thread = await ref.read(threadsProvider.notifier).createThread();
    ref.read(selectedThreadIdProvider.notifier).state = thread.id;
    ref.read(chatProvider.notifier).loadMessages(thread.id);
  }

  @override
  Widget build(BuildContext context) {
    // Connect once auth finishes loading — needed because AuthNotifier loads
    // credentials asynchronously (isLoading: true on first build).
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!next.isLoading && next.isAuthenticated) {
        _ensureGatewayConnected();
      }
    });

    // Immediate connect if auth is already available on first render.
    _ensureGatewayConnected();

    // Trigger agent identity fetch as soon as the gateway connects (or
    // reconnects). Widget-layer ref.listen is guaranteed to fire for every
    // state change, making this more reliable than a listener inside the
    // provider factory.
    ref.listen<GatewayState>(gatewayProvider, (_, next) {
      if (next.status == GatewayStatus.connected) {
        ref
            .read(agentIdentityProvider.notifier)
            .fetchIfNeeded(next.hello?.connId);
      }
    });

    // Also handle the case where the gateway is already connected when this
    // page first renders (ref.listen only fires on future changes).
    final currentGateway = ref.read(gatewayProvider);
    if (currentGateway.status == GatewayStatus.connected) {
      ref
          .read(agentIdentityProvider.notifier)
          .fetchIfNeeded(currentGateway.hello?.connId);
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppConstants.breakpointDesktop;
    final selectedId = ref.watch(selectedThreadIdProvider);

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppHeader(showMenuButton: !isDesktop),
        // Mobile/tablet: thread list in a standard M3 Drawer
        drawer: !isDesktop ? const Drawer(child: ThreadList()) : null,
        // Settings panel as an end drawer on all screen sizes
        endDrawer: const Drawer(
          width: AppConstants.settingsPanelWidth,
          child: SettingsPanel(),
        ),
        body: Row(
          children: [
            // Desktop: persistent sidebar
            if (isDesktop)
              Container(
                width: AppConstants.sidebarWidth,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: const ThreadList(),
              ),
            // Chat area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: KeyedSubtree(
                  key: ValueKey(selectedId),
                  child: const ChatArea(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
