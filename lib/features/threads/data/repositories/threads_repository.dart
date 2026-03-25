import 'package:hive_flutter/hive_flutter.dart';
import '../models/thread_model.dart';

class ThreadsRepository {
  static const _boxName = 'threads';

  Box<ThreadModel> get _box => Hive.box<ThreadModel>(_boxName);

  List<ThreadModel> getAllThreads() {
    return _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  ThreadModel? getThread(String id) => _box.get(id);

  Future<void> saveThread(ThreadModel thread) async {
    await _box.put(thread.id, thread);
  }

  Future<void> deleteThread(String id) async {
    await _box.delete(id);
  }

  Future<void> updateTitle(String id, String title) async {
    final thread = _box.get(id);
    if (thread != null) {
      thread.title = title;
      thread.updatedAt = DateTime.now();
      await thread.save();
    }
  }

  Future<void> touchThread(String id) async {
    final thread = _box.get(id);
    if (thread != null) {
      thread.updatedAt = DateTime.now();
      await thread.save();
    }
  }
}
