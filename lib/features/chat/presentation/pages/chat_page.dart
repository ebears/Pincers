import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../threads/presentation/widgets/thread_list.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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
  bool _sidebarVisible = true;
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

    // Escape → close settings panel, or collapse sidebar on mobile/tablet
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final settingsOpen = ref.read(settingsProvider).isPanelOpen;
      if (settingsOpen) {
        ref.read(settingsProvider.notifier).togglePanel();
        return KeyEventResult.handled;
      }
      final width = MediaQuery.of(context).size.width;
      final isDesktop = width >= AppConstants.breakpointDesktop;
      if (!isDesktop && _sidebarVisible) {
        setState(() => _sidebarVisible = false);
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
    final isTablet = width >= AppConstants.breakpointTablet;
    final selectedId = ref.watch(selectedThreadIdProvider);
    final settingsOpen = ref.watch(settingsProvider).isPanelOpen;

    if (!isTablet && _sidebarVisible && selectedId != null) {
      _sidebarVisible = false;
    }

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Column(
          children: [
            AppHeader(
              showMenuButton: !isDesktop,
              onMenuTap: () =>
                  setState(() => _sidebarVisible = !_sidebarVisible),
            ),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Sidebar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        width: (isDesktop ||
                                (isTablet && _sidebarVisible) ||
                                (!isTablet && _sidebarVisible))
                            ? AppConstants.sidebarWidth
                            : 0,
                        child: OverflowBox(
                          maxWidth: AppConstants.sidebarWidth,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: AppConstants.sidebarWidth,
                            color: AppColors.bgSecondary,
                            child: const ThreadList(),
                          ),
                        ),
                      ),
                      // Chat area with swipe-right to reveal sidebar on mobile
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: !isTablet
                              ? (details) {
                                  if (details.primaryVelocity != null &&
                                      details.primaryVelocity! > 300) {
                                    setState(() => _sidebarVisible = true);
                                  }
                                }
                              : null,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: KeyedSubtree(
                              key: ValueKey(selectedId),
                              child: const ChatArea(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Settings panel overlay
                  if (settingsOpen) const SettingsPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
