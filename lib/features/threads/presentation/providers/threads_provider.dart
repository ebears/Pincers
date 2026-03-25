import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/thread_model.dart';
import '../../data/repositories/threads_repository.dart';

final _uuid = Uuid();

class ThreadsNotifier extends StateNotifier<List<ThreadModel>> {
  final ThreadsRepository _repo;

  ThreadsNotifier(this._repo) : super([]) {
    loadThreads();
  }

  void loadThreads() {
    state = _repo.getAllThreads();
  }

  Future<ThreadModel> createThread() async {
    final now = DateTime.now();
    final thread = ThreadModel(
      id: _uuid.v4(),
      title: 'New conversation',
      createdAt: now,
      updatedAt: now,
    );
    await _repo.saveThread(thread);
    loadThreads();
    return thread;
  }

  Future<void> deleteThread(String id) async {
    await _repo.deleteThread(id);
    loadThreads();
  }

  Future<void> updateTitle(String id, String title) async {
    await _repo.updateTitle(id, title);
    loadThreads();
  }

  Future<void> touchThread(String id) async {
    await _repo.touchThread(id);
    loadThreads();
  }
}

final threadsRepositoryProvider = Provider<ThreadsRepository>((ref) {
  return ThreadsRepository();
});

final threadsProvider = StateNotifierProvider<ThreadsNotifier, List<ThreadModel>>((ref) {
  return ThreadsNotifier(ref.watch(threadsRepositoryProvider));
});

final selectedThreadIdProvider = StateProvider<String?>((ref) => null);
