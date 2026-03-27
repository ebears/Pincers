import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../features/chat/presentation/widgets/agent_avatar.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final bool showMenuButton;

  const AppHeader({super.key, this.showMenuButton = false});

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.headerHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: AppConstants.headerHeight,
      automaticallyImplyLeading: false,
      leading: showMenuButton
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open menu',
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgentAvatar(size: 24),
          const SizedBox(width: AppConstants.space8),
          Text(
            'Pincers',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
          tooltip: 'Settings',
        ),
        const SizedBox(width: AppConstants.space4),
      ],
    );
  }
}

