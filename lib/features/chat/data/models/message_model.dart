import 'package:hive/hive.dart';
import 'attachment_model.dart';

part 'message_model.g.dart';

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String threadId;

  @HiveField(2)
  late String role; // 'user' | 'bot'

  @HiveField(3)
  late String content;

  @HiveField(4)
  late List<AttachmentModel> attachments;

  @HiveField(5)
  late DateTime createdAt;

  MessageModel({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.attachments,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isBot => role == 'bot';
}
