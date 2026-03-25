import '../../data/models/attachment_model.dart';

class Message {
  final String id;
  final String threadId;
  final String role;
  final String content;
  final List<AttachmentModel> attachments;
  final DateTime createdAt;

  const Message({
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
