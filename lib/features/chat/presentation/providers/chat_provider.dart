import 'dart:async';
import 'dart:convert';
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
  /// Tracks which sessions this connection is subscribed to: sessionKey → connId.
  /// Used to avoid re-subscribing on the same connection and to detect reconnection.
  final Map<String, String> _subscribedSessions = {};
  /// Maps runId → sessionKey so _handleFinal can check subscription status.
  final Map<String, String> _runSessionMap = {};
  /// Fingerprints of content recently finalized via streaming, used to
  /// de-duplicate session.message events that arrive after streaming completes.
  final Map<String, DateTime> _recentStreamedContents = {};

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
    } else if (event == 'session.message') {
      final payload = (msg['payload'] as Map<String, dynamic>?) ?? {};
      _handleSessionMessage(payload);
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

    // Track which thread and session this run belongs to.
    _runThreadMap[runId] = threadId;
    if (sessionKey != null) _runSessionMap[runId] = sessionKey;

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
      _markContentAsStreamed(finalMsg.content);
      _cleanupRun(runId);
      _ref.read(threadsProvider.notifier).touchThread(threadId);
    } else {
      // No deltas preceded this — either a non-streaming response or a gateway
      // "silent reply" (agent intentionally suppressed output).
      if (content.isNotEmpty) {
        // When subscribed to session.message events, the same content will
        // arrive (or already has) via session.message — suppress here to avoid
        // duplicates. Fall back to direct display when not subscribed.
        final sessKey = _runSessionMap.remove(runId);
        final subscribed =
            sessKey != null && _subscribedSessions.containsKey(sessKey);
        if (!subscribed) {
          _receiveBotMessage(threadId, content);
        }
      } else {
        debugPrint(
            '[Pincers] Silent reply: agent sent no content for run $runId');
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
    _runSessionMap.remove(runId);
  }

  /// Handles a `session.message` event from the gateway.
  ///
  /// When subscribed via `sessions.messages.subscribe`, the gateway delivers
  /// ALL messages for the session — including multi-run tool-call responses
  /// that never arrive via `chat` events alone (the `chat.send` run ends with
  /// a silent final while the actual answer lands in a separate run).
  ///
  /// When verbose mode is on, messages with `stopReason: toolUse` are also
  /// processed: each `toolCall` content block is rendered as a transient
  /// verbose activity entry (not persisted to Hive).
  ///
  /// We display only final assistant messages with visible text, skipping
  /// thinking blocks, user echoes, and anything already shown via streaming
  /// `chat` events.
  void _handleSessionMessage(Map<String, dynamic> payload) {
    final message = payload['message'] as Map<String, dynamic>?;
    if (message == null) return;

    if ((message['role'] as String?) != 'assistant') return;

    final stopReason = message['stopReason'] as String?;
    final sessionKey = payload['sessionKey'] as String?;
    final threadId = _resolveThreadId(sessionKey);
    if (threadId == null) return;

    // In verbose mode, capture tool-call activity from tool-use stops.
    if (stopReason == 'toolUse' && _ref.read(verboseModeProvider)) {
      for (final call in _extractToolCalls(message)) {
        _addVerboseMessage(threadId, call.$1, call.$2);
      }
      return;
    }

    // Only display final assistant messages with visible text.
    if (stopReason != 'stop') return;

    // Extract visible text — thinking/toolCall blocks yield an empty string.
    final content = _stripTrailingTag(_extractContent(message));
    if (content.isEmpty) return;

    // Skip if this content was just finalized via streaming chat events.
    if (_wasRecentlyStreamed(content)) return;

    // Skip if the streaming path is currently building this thread's response.
    // The chat-event pipeline (delta → final) will finalize it; delivering here
    // too would create a duplicate.
    if (_runThreadMap.values.any((t) => t == threadId)) return;

    _receiveBotMessage(threadId, content);
  }

  /// Extracts `toolCall` content blocks from a message, returning
  /// `(toolName, argsJson)` pairs for each call found.
  List<(String, String)> _extractToolCalls(Map<String, dynamic> message) {
    final content = message['content'];
    if (content is! List) return const [];
    final results = <(String, String)>[];
    for (final block in content) {
      if (block is Map && block['type'] == 'toolCall') {
        final name = (block['name'] as String?) ?? 'unknown_tool';
        final args = block['arguments'];
        final argsJson = args == null
            ? '{}'
            : (args is String ? args : jsonEncode(args));
        results.add((name, argsJson));
      }
    }
    return results;
  }

  /// Appends a transient verbose message to state without persisting to Hive.
  ///
  /// Content is encoded as `"$toolName\n$argsJson"` so [VerboseBubble] can
  /// split on the first newline to recover the two parts.
  void _addVerboseMessage(String threadId, String toolName, String argsJson) {
    final msg = MessageModel(
      id: _uuid.v4(),
      threadId: threadId,
      role: 'verbose',
      content: '$toolName\n$argsJson',
      attachments: const [],
      createdAt: DateTime.now(),
    );
    state = [...state, msg];
  }

  void _markContentAsStreamed(String content) {
    if (content.isEmpty) return;
    _recentStreamedContents[_contentFingerprint(content)] = DateTime.now();
  }

  bool _wasRecentlyStreamed(String content) {
    final fp = _contentFingerprint(content);
    final when = _recentStreamedContents[fp];
    if (when == null) return false;
    if (DateTime.now().difference(when).inSeconds > 5) {
      _recentStreamedContents.remove(fp);
      return false;
    }
    return true;
  }

  /// Short fingerprint to detect duplicate content across chat/session.message
  /// event paths without comparing full strings.
  String _contentFingerprint(String s) {
    final t = s.trim();
    if (t.length <= 60) return t;
    return '${t.substring(0, 30)}|${t.length}|${t.substring(t.length - 30)}';
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

  /// Subscribes this WebSocket connection to all chat events for [sessionKey].
  ///
  /// The gateway only delivers multi-run responses (tool calls, verbose output)
  /// to connections that have explicitly subscribed via `sessions.messages.subscribe`.
  /// Without this, Pincers only receives events for the single run directly
  /// tied to its `chat.send` request, and gets a silent final for everything else.
  ///
  /// Subscriptions are per-connection — they must be re-established after
  /// reconnection. [_subscribedSessions] tracks sessionKey → connId so we
  /// skip redundant calls on the same connection.
  Future<void> _subscribeToSessionIfNeeded(String sessionKey) async {
    final connId = _ref.read(gatewayProvider).hello?.connId;
    if (connId == null) return;
    if (_subscribedSessions[sessionKey] == connId) return;

    try {
      await _ref.read(gatewayProvider.notifier).sendRequest(
        'sessions.messages.subscribe',
        {'key': sessionKey},
      );
      _subscribedSessions[sessionKey] = connId;
      debugPrint('[Pincers] Subscribed to session events: $sessionKey');
    } catch (e) {
      debugPrint('[Pincers] Session subscribe failed (non-fatal): $e');
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

      // Subscribe to receive all chat events for this session, including
      // multi-run responses produced when the agent uses tools.
      await _subscribeToSessionIfNeeded(sessionKey);

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

/// Controls whether verbose tool-call activity is shown in the chat.
/// Transient — not persisted across app restarts.
final verboseModeProvider = StateProvider<bool>((ref) => false);
