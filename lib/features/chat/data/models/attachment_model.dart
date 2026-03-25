import 'package:hive/hive.dart';

part 'attachment_model.g.dart';

@HiveType(typeId: 2)
class AttachmentModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String filename;

  @HiveField(2)
  late String mimeType;

  @HiveField(3)
  late int sizeBytes;

  @HiveField(4)
  late String base64Data;

  AttachmentModel({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.base64Data,
  });
}
