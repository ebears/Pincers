import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'shared/services/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set minimum window size on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(800, 600));
  }

  // Open settings box for auth (untyped) and init typed boxes
  await HiveService.init();

  runApp(
    const ProviderScope(
      child: PincersApp(),
    ),
  );
}
