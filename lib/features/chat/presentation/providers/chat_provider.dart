import 'dart:async';
import 'package:flutter/foundation.dart';
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

  /// Tracks in-progress streaming bot messages: runId → messageId
  final Map<String, String> _streamingIds = {};
  /// Accumulates streaming content per run: runId → content so far
  final Map<String, StringBuffer> _streamingBuffers = {};
  /// Maps runId → threadId so we know which thread a streaming run belongs to
  final Map<String, String> _runThreadMap = {};

  StreamSubscription<Map<String, dynamic>>? _eventSub;

  ChatNotifier(this._repo, this._ref) : super([]) {
    _eventSub = _ref
        .read(gatewayProvider.notifier)
        .events
        .listen(_handleGatewayEvent);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  // ── Incoming event routing ────────────────────────────────────────────────

  void _handleGatewayEvent(Map<String, dynamic> msg) {
    if (!mounted) return;

    final event = msg['event'] as String?;
    debugPrint('[Pincers] Gateway event: $event');
    if (event == 'chat') {
      final payload = (msg['payload'] as Map<String, dynamic>?) ?? {};
      _handleChatEvent(payload);
    }
  }

  void _handleChatEvent(Map<String, dynamic> payload) {
    final eventState = payload['state'] as String?;
    final runId = payload['runId'] as String?;
    final sessionKey = payload['sessionKey'] as String?;
    final message = payload['message'] as Map<String, dynamic>?;

    debugPrint('[Pincers] chat event: state=$eventState runId=$runId');

    if (runId == null) return;

    // Resolve threadId from sessionKey.
    final threadId = _resolveThreadId(sessionKey);
    if (threadId == null) return;

    // Track which thread this run belongs to.
    _runThreadMap[runId] = threadId;

    switch (eventState) {
      case 'delta':
        _handleDelta(runId, threadId, message);
      case 'final':
        _handleFinal(runId, threadId, message);
      case 'error':
      case 'aborted':
        _handleErrorOrAbort(runId, threadId, payload);
    }
  }

  String? _resolveThreadId(String? sessionKey) {
    if (sessionKey == null) return _ref.read(selectedThreadIdProvider);
    final threads = _ref.read(threadsProvider);
    final match = threads.where((t) => t.sessionId == sessionKey).firstOrNull;
    return match?.id ?? _ref.read(selectedThreadIdProvider);
  }

  void _handleDelta(
      String runId, String threadId, Map<String, dynamic>? message) {
    final content = _extractContent(message);

    if (!_streamingIds.containsKey(runId)) {
      // First delta: dismiss typing indicator, create placeholder message.
      _ref.read(typingProvider.notifier).state = false;
      final id = _uuid.v4();
      _streamingIds[runId] = id;
      _streamingBuffers[runId] = StringBuffer(content);
      final partialMsg = MessageModel(
        id: id,
        threadId: threadId,
        role: 'bot',
        content: content,
        attachments: const [],
        createdAt: DateTime.now(),
      );
      state = [...state, partialMsg];
    } else {
      _streamingBuffers[runId]!.write(content);
      final id = _streamingIds[runId]!;
      final newContent = _streamingBuffers[runId]!.toString();
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
  }

  void _handleFinal(
      String runId, String threadId, Map<String, dynamic>? message) {
    _ref.read(typingProvider.notifier).state = false;

    final content = _stripTrailingTag(_extractContent(message));

    if (_streamingIds.containsKey(runId)) {
      // Finalize the streaming message.
      final id = _streamingIds[runId]!;
      if (content.isNotEmpty) {
        // Replace accumulated delta content with the authoritative final text.
        state = [
          for (final m in state)
            if (m.id == id)
              MessageModel(
                id: m.id,
                threadId: m.threadId,
                role: m.role,
                content: content,
                attachments: m.attachments,
                createdAt: m.createdAt,
              )
            else
              m,
        ];
      }
      final finalMsg = state.firstWhere((m) => m.id == id);
      _repo.saveMessage(finalMsg);
      _cleanupRun(runId);
      _ref.read(threadsProvider.notifier).touchThread(threadId);
    } else {
      // No deltas preceded this — either a non-streaming response or a gateway
      // "silent reply" (agent intentionally suppressed output). Only show a
      // message if there's actually content.
      if (content.isNotEmpty) {
        _receiveBotMessage(threadId, content);
      } else {
        debugPrint('[Pincers] Silent reply: agent sent no content for run $runId');
      }
    }
  }

  void _handleErrorOrAbort(String runId, String threadId, Map<String, dynamic> payload) {
    _ref.read(typingProvider.notifier).state = false;

    final eventState = payload['state'] as String?;
    final errorMsg = (payload['error'] as Map<String, dynamic>?)?['message'] as String?
        ?? payload['message'] as String?;
    debugPrint('[Pincers] chat $eventState: $errorMsg');

    if (_streamingIds.containsKey(runId)) {
      // Persist whatever we accumulated.
      final id = _streamingIds[runId]!;
      final msg = state.where((m) => m.id == id).firstOrNull;
      if (msg != null && msg.content.isNotEmpty) {
        _repo.saveMessage(msg);
      }
      _cleanupRun(runId);
    } else {
      // No deltas — show an error bubble so the user knows something went wrong.
      final display = eventState == 'aborted'
          ? 'Response was stopped.'
          : (errorMsg?.isNotEmpty == true ? errorMsg! : 'An error occurred. Please try again.');
      _receiveBotMessage(threadId, display);
    }
  }

  void _cleanupRun(String runId) {
    _streamingIds.remove(runId);
    _streamingBuffers.remove(runId);
    _runThreadMap.remove(runId);
  }

  /// Strip any trailing incomplete XML/HTML tag (e.g. `</` or `</think`) that
  /// some LLMs emit as streaming artifacts before the gateway sends `final`.
  String _stripTrailingTag(String s) =>
      s.replaceFirst(RegExp(r'<[^>]*$'), '').trimRight();

  /// Extract text content from a message payload.
  String _extractContent(Map<String, dynamic>? message) {
    if (message == null) return '';
    // The message may have a 'content' field that's a string or a list of blocks.
    final content = message['content'];
    if (content is String) return content;
    if (content is List) {
      final buffer = StringBuffer();
      for (final block in content) {
        if (block is Map && block['type'] == 'text') {
          buffer.write(block['text'] ?? '');
        }
      }
      return buffer.toString();
    }
    // Fallback: check for 'text' directly.
    final text = message['text'];
    if (text is String) return text;
    return '';
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  void loadMessages(String threadId) {
    state = _repo.getMessagesForThread(threadId);
  }

  /// Ensure the thread has a gateway session; create one lazily if not.
  Future<String> _ensureSession(String threadId) async {
    final threads = _ref.read(threadsProvider);
    final thread = threads.firstWhere((t) => t.id == threadId,
        orElse: () => throw StateError('Thread not found'));

    if (thread.sessionId != null) return thread.sessionId!;

    // Use thread ID as unique session label to avoid collisions.
    final label = 'pincers-$threadId';

    try {
      final result = await _ref.read(gatewayProvider.notifier).sendRequest(
        'sessions.create',
        {'label': label},
      );
      final sessionKey = result['key'] as String? ??
          result['sessionKey'] as String? ??
          '';
      if (sessionKey.isEmpty) {
        throw StateError('Gateway returned no session key');
      }

      await _ref
          .read(threadsProvider.notifier)
          .updateSessionId(threadId, sessionKey);
      return sessionKey;
    } catch (e) {
      // If the label is already in use, try to find the existing session.
      if (e.toString().contains('label already in use')) {
        debugPrint('[Pincers] Session label collision, listing sessions...');
        final listResult = await _ref
            .read(gatewayProvider.notifier)
            .sendRequest('sessions.list', {});
        final sessions = (listResult['sessions'] as List<dynamic>?) ?? [];
        for (final s in sessions) {
          if (s is Map<String, dynamic> && s['label'] == label) {
            final sessionKey = s['key'] as String? ??
                s['sessionKey'] as String? ??
                '';
            if (sessionKey.isNotEmpty) {
              await _ref
                  .read(threadsProvider.notifier)
                  .updateSessionId(threadId, sessionKey);
              return sessionKey;
            }
          }
        }
      }
      rethrow;
    }
  }

  Future<void> sendMessage(String threadId, String content,
      {List<AttachmentModel> attachments = const []}) async {
    // Optimistically add user message.
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

    // Update thread title from first message.
    final threads = _ref.read(threadsProvider);
    final thread = threads.firstWhere((t) => t.id == threadId,
        orElse: () => throw StateError('Thread not found'));
    if (thread.title == 'New conversation') {
      final title = content.length > AppConstants.threadTitleMaxLength
          ? content.substring(0, AppConstants.threadTitleMaxLength)
          : content;
      await _ref.read(threadsProvider.notifier).updateTitle(threadId, title);
      final preview = content.length > 60 ? content.substring(0, 60) : content;
      await _ref.read(threadsProvider.notifier).updatePreview(threadId, preview);
    }
    await _ref.read(threadsProvider.notifier).touchThread(threadId);

    // Show typing indicator.
    _ref.read(typingProvider.notifier).state = true;

    try {
      // Wait for gateway connection if still connecting.
      debugPrint('[Pincers] Waiting for gateway connection...');
      await _ref.read(gatewayProvider.notifier).waitForConnection();
      debugPrint('[Pincers] Gateway connected, ensuring session...');

      final sessionKey = await _ensureSession(threadId);
      debugPrint('[Pincers] Session key: $sessionKey, sending chat.send...');

      // Format attachments per OpenClaw spec.
      final formattedAttachments = attachments.map(_formatAttachment).toList();

      await _ref.read(gatewayProvider.notifier).sendRequest(
        'chat.send',
        {
          'sessionKey': sessionKey,
          'message': content,
          if (formattedAttachments.isNotEmpty)
            'attachments': formattedAttachments,
          'idempotencyKey': msg.id,
        },
      );
      debugPrint('[Pincers] chat.send request acknowledged by gateway');
    } catch (e) {
      debugPrint('[Pincers] Send failed: $e');
      // On send failure, hide typing. Error is surfaced to UI via the throw.
      _ref.read(typingProvider.notifier).state = false;
      rethrow;
    }
  }

  Map<String, dynamic> _formatAttachment(AttachmentModel a) {
    if (a.mimeType.startsWith('image/')) {
      return {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': a.mimeType,
          'data': a.base64Data,
        },
      };
    }
    return {
      'type': 'document',
      'source': {
        'type': 'base64',
        'media_type': a.mimeType,
        'data': a.base64Data,
      },
    };
  }

  Future<void> _receiveBotMessage(String threadId, String content) async {
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
