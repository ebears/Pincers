import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/thread_model.dart';
import '../../data/repositories/threads_repository.dart';

final _uuid = Uuid();

class ThreadsNotifier extends StateNotifier<List<ThreadModel>> {
  final ThreadsRepository _repo;
  final Ref _ref;

  ThreadsNotifier(this._repo, this._ref) : super([]) {
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
    // Highlight the new thread briefly
    _ref.read(newlyCreatedThreadIdProvider.notifier).state = thread.id;
    Future.delayed(const Duration(seconds: 2), () {
      if (_ref.read(newlyCreatedThreadIdProvider) == thread.id) {
        _ref.read(newlyCreatedThreadIdProvider.notifier).state = null;
      }
    });
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

  Future<void> updatePreview(String id, String preview) async {
    await _repo.updatePreview(id, preview);
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
  return ThreadsNotifier(ref.watch(threadsRepositoryProvider), ref);
});

final selectedThreadIdProvider = StateProvider<String?>((ref) => null);

final newlyCreatedThreadIdProvider = StateProvider<String?>((ref) => null);
