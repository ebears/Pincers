import 'dart:async';
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

  // Tracks in-progress streaming bot messages: threadId → messageId
  final Map<String, String> _streamingIds = {};
  // Accumulates streaming content per thread: threadId → content so far
  final Map<String, StringBuffer> _streamingBuffers = {};

  StreamSubscription<Map<String, dynamic>>? _messageSub;

  ChatNotifier(this._repo, this._ref) : super([]) {
    _messageSub = _ref
        .read(gatewayProvider.notifier)
        .messages
        .listen(_handleGatewayMessage);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  // ── Incoming message routing ────────────────────────────────────────────────

  void _handleGatewayMessage(Map<String, dynamic> msg) {
    if (!mounted) return;

    if (msg.containsKey('method')) {
      // JSON-RPC notification
      final method = msg['method'] as String;
      final params = (msg['params'] as Map<String, dynamic>?) ?? {};
      switch (method) {
        case 'session.token':
          _handleStreamToken(params);
        case 'session.message':
          // Non-streaming complete message via notification
          final threadId = params['thread_id'] as String?;
          final content = params['content'] as String?;
          if (threadId != null && content != null) {
            receiveBotMessage(threadId, content);
          }
      }
    } else if (msg.containsKey('id') && msg.containsKey('result')) {
      // JSON-RPC success response — treat as complete bot message
      final result = (msg['result'] as Map<String, dynamic>?) ?? {};
      final content = result['content'] as String?;
      final threadId =
          result['thread_id'] as String? ?? _ref.read(selectedThreadIdProvider);
      if (content != null && threadId != null) {
        receiveBotMessage(threadId, content);
      }
    }
  }

  void _handleStreamToken(Map<String, dynamic> params) {
    final threadId = params['thread_id'] as String?;
    final token = params['content'] as String? ?? '';
    final done = params['done'] as bool? ?? false;

    if (threadId == null) return;

    // Dismiss typing indicator on first token
    if (!_streamingIds.containsKey(threadId)) {
      _ref.read(typingProvider.notifier).state = false;
      final id = _uuid.v4();
      _streamingIds[threadId] = id;
      _streamingBuffers[threadId] = StringBuffer(token);
      final partialMsg = MessageModel(
        id: id,
        threadId: threadId,
        role: 'bot',
        content: token,
        attachments: const [],
        createdAt: DateTime.now(),
      );
      state = [...state, partialMsg];
    } else {
      _streamingBuffers[threadId]!.write(token);
      final id = _streamingIds[threadId]!;
      final newContent = _streamingBuffers[threadId]!.toString();
      state = [
        for (final m in state)
          if (m.id == id)
            MessageModel(
              id: m.id,
              threadId: m.threadId,
              role: m.role,
              content: newContent,
              attachments: m.attachments,
              createdAt: m.createdAt,
            )
          else
            m,
      ];
    }

    if (done) {
      final id = _streamingIds[threadId]!;
      final finalMsg = state.firstWhere((m) => m.id == id);
      _repo.saveMessage(finalMsg);
      _streamingIds.remove(threadId);
      _streamingBuffers.remove(threadId);
      _ref.read(threadsProvider.notifier).touchThread(threadId);
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  void loadMessages(String threadId) {
    state = _repo.getMessagesForThread(threadId);
  }

  Future<void> sendMessage(String threadId, String content,
      {List<AttachmentModel> attachments = const []}) async {
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
    final thread = threads.firstWhere((t) => t.id == threadId,
        orElse: () => throw StateError('Thread not found'));
    if (thread.title == 'New conversation') {
      final title = content.length > AppConstants.threadTitleMaxLength
          ? content.substring(0, AppConstants.threadTitleMaxLength)
          : content;
      await _ref.read(threadsProvider.notifier).updateTitle(threadId, title);
      // Also set the preview from the first message
      final preview = content.length > 60 ? content.substring(0, 60) : content;
      await _ref.read(threadsProvider.notifier).updatePreview(threadId, preview);
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
          if (attachments.isNotEmpty)
            'attachments': attachments
                .map((a) => {
                      'id': a.id,
                      'filename': a.filename,
                      'mime_type': a.mimeType,
                      'data': a.base64Data,
                    })
                .toList(),
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
      attachments: const [],
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

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<MessageModel>>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider), ref);
});
