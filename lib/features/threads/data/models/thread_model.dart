import 'package:hive/hive.dart';

part 'thread_model.g.dart';

@HiveType(typeId: 0)
class ThreadModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late DateTime updatedAt;

  @HiveField(4)
  String? sessionId;

  ThreadModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
  });
}
