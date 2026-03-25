import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'shared/services/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open settings box for auth (untyped)
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Init typed boxes
  await HiveService.init();

  runApp(
    const ProviderScope(
      child: PincersApp(),
    ),
  );
}
