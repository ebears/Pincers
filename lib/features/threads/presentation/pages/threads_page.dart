import 'package:flutter/material.dart';
import '../widgets/thread_list.dart';

/// Standalone page wrapping ThreadList.
/// Used for dedicated mobile navigation to the thread browser.
class ThreadsPage extends StatelessWidget {
  const ThreadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ThreadList(),
    );
  }
}
