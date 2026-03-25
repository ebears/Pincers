import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../threads/presentation/widgets/thread_list.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/settings_panel.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/chat_area.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  bool _sidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppConstants.breakpointDesktop;
    final isTablet = width >= AppConstants.breakpointTablet;
    final selectedId = ref.watch(selectedThreadIdProvider);
    final settingsOpen = ref.watch(settingsProvider).isPanelOpen;

    if (!isTablet && _sidebarVisible && selectedId != null) {
      _sidebarVisible = false;
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          AppHeader(
            showMenuButton: !isDesktop,
            onMenuTap: () => setState(() => _sidebarVisible = !_sidebarVisible),
          ),
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    // Sidebar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: (isDesktop || (isTablet && _sidebarVisible) || (!isTablet && _sidebarVisible))
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
                    // Chat area
                    const Expanded(child: ChatArea()),
                  ],
                ),
                // Settings panel overlay
                if (settingsOpen) const SettingsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
