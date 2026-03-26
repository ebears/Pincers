import 'package:flutter/material.dart';
import '../widgets/settings_panel.dart';

/// Standalone page wrapping SettingsPanel content.
/// Used for dedicated mobile navigation to settings.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SettingsPanel(),
    );
  }
}
