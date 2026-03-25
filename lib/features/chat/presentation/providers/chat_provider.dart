import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/message_model.dart';
import '../../data/models/attachment_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../threads/presentation/providers/threads_provider.dart';
import '../../../../core/constants/app_constants.dart';
import 'typing_provider.dart';
import 'gateway_provider.dart';

final _uuid = Uuid();

class ChatNotifier extends StateNotifier<List<MessageModel>> {
  final ChatRepository _repo;
  final Ref _ref;

  ChatNotifier(this._repo, this._ref) : super([]);

  void loadMessages(String threadId) {
    state = _repo.getMessagesForThread(threadId);
  }

  Future<void> sendMessage(String threadId, String content, {List<AttachmentModel> attachments = const []}) async {
    final msg = MessageModel(
      id: _uuid.v4(),
      threadId: threadId,
      role: 'user',
      content: content,
      attachments: attachments,
      createdAt: DateTime.now(),
    );
    await _repo.saveMessage(msg);
    state = [...state, msg];

    // Update thread title from first message
    final threads = _ref.read(threadsProvider);
    final thread = threads.firstWhere((t) => t.id == threadId, orElse: () => throw StateError('Thread not found'));
    if (thread.title == 'New conversation') {
      final title = content.length > AppConstants.threadTitleMaxLength
          ? content.substring(0, AppConstants.threadTitleMaxLength)
          : content;
      await _ref.read(threadsProvider.notifier).updateTitle(threadId, title);
    }
    await _ref.read(threadsProvider.notifier).touchThread(threadId);

    // Show typing indicator and send to gateway
    _ref.read(typingProvider.notifier).state = true;
    try {
      await _ref.read(gatewayProvider.notifier).send(
        'session.send',
        {
          'thread_id': threadId,
          'content': content,
          if (attachments.isNotEmpty) 'attachments': attachments.map((a) => {'id': a.id, 'filename': a.filename, 'mime_type': a.mimeType, 'data': a.base64Data}).toList(),
        },
        id: msg.id,
      );
    } catch (_) {
      // Error handling is done at the UI layer
    }
  }

  Future<void> receiveBotMessage(String threadId, String content) async {
    _ref.read(typingProvider.notifier).state = false;
    final msg = MessageModel(
      id: _uuid.v4(),
      threadId: threadId,
      role: 'bot',
      content: content,
      attachments: [],
      createdAt: DateTime.now(),
    );
    await _repo.saveMessage(msg);
    state = [...state, msg];
    await _ref.read(threadsProvider.notifier).touchThread(threadId);
  }

  Future<void> clearMessages(String threadId) async {
    await _repo.deleteMessagesForThread(threadId);
    state = [];
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

final chatProvider = StateNotifierProvider<ChatNotifier, List<MessageModel>>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider), ref);
});
