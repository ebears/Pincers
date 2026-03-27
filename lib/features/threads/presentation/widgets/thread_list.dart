import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/time_utils.dart';
import '../../data/models/thread_model.dart';
import '../providers/threads_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import 'thread_item.dart';
import 'thread_group_header.dart';

class ThreadList extends ConsumerStatefulWidget {
  const ThreadList({super.key});

  @override
  ConsumerState<ThreadList> createState() => _ThreadListState();
}

class _ThreadListState extends ConsumerState<ThreadList> {
  final Set<String> _collapsedGroups = {'This Week', 'Earlier'};

  void _toggleGroup(String label) {
    setState(() {
      if (_collapsedGroups.contains(label)) {
        _collapsedGroups.remove(label);
      } else {
        _collapsedGroups.add(label);
      }
    });
  }

  Future<void> _createThread() async {
    final thread = await ref.read(threadsProvider.notifier).createThread();
    ref.read(selectedThreadIdProvider.notifier).state = thread.id;
    ref.read(chatProvider.notifier).loadMessages(thread.id);
    // Close drawer when running in mobile/tablet mode
    if (mounted) Scaffold.maybeOf(context)?.closeDrawer();
  }

  void _selectThread(ThreadModel thread) {
    ref.read(selectedThreadIdProvider.notifier).state = thread.id;
    ref.read(chatProvider.notifier).loadMessages(thread.id);
    // Close drawer when running in mobile/tablet mode
    Scaffold.maybeOf(context)?.closeDrawer();
  }

  void _confirmDelete(String id) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delete conversation?',
              style: textTheme.bodyMedium,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    final selectedId = ref.read(selectedThreadIdProvider);
                    await ref.read(threadsProvider.notifier).deleteThread(id);
                    if (selectedId == id) {
                      ref.read(selectedThreadIdProvider.notifier).state = null;
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<ThreadModel>> _groupThreads(List<ThreadModel> threads) {
    final groups = <String, List<ThreadModel>>{};
    for (final t in threads) {
      final label = TimeUtils.groupLabel(t.updatedAt);
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(threadsProvider);
    final selectedId = ref.watch(selectedThreadIdProvider);
    final groups = _groupThreads(threads);
    final sortedLabels = ['Today', 'Yesterday', 'This Week', 'Earlier']
        .where((l) => groups.containsKey(l))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: AppConstants.space8),
            itemCount: sortedLabels.fold<int>(0, (sum, l) {
              final collapsed = _collapsedGroups.contains(l);
              return sum + 1 + (collapsed ? 0 : (groups[l]?.length ?? 0));
            }),
            itemBuilder: (context, index) {
              int remaining = index;
              for (final label in sortedLabels) {
                if (remaining == 0) {
                  return ThreadGroupHeader(
                    label: label,
                    isCollapsed: _collapsedGroups.contains(label),
                    onToggle: () => _toggleGroup(label),
                  );
                }
                remaining--;
                if (!_collapsedGroups.contains(label)) {
                  final items = groups[label] ?? [];
                  if (remaining < items.length) {
                    final thread = items[remaining];
                    return ThreadItem(
                      key: ValueKey(thread.id),
                      staggerIndex: remaining,
                      thread: thread,
                      isSelected: thread.id == selectedId,
                      onTap: () => _selectThread(thread),
                      onDelete: () => _confirmDelete(thread.id),
                    );
                  }
                  remaining -= groups[label]!.length;
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppConstants.space12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _createThread,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New conversation'),
            ),
          ),
        ),
      ],
    );
  }
}
