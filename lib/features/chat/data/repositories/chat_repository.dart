import 'package:hive_flutter/hive_flutter.dart';
import '../models/message_model.dart';

class ChatRepository {
  static const _boxName = 'messages';

  Box<MessageModel> get _box => Hive.box<MessageModel>(_boxName);

  List<MessageModel> getMessagesForThread(String threadId) {
    return _box.values
        .where((m) => m.threadId == threadId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveMessage(MessageModel message) async {
    await _box.put(message.id, message);
  }

  Future<void> deleteMessagesForThread(String threadId) async {
    final keys = _box.values
        .where((m) => m.threadId == threadId)
        .map((m) => m.key)
        .toList();
    await _box.deleteAll(keys);
  }
}
