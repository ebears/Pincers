import 'package:hive_flutter/hive_flutter.dart';
import '../../features/threads/data/models/thread_model.dart';
import '../../features/chat/data/models/message_model.dart';
import '../../features/chat/data/models/attachment_model.dart';
import '../../features/profile/data/models/user_profile_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ThreadModelAdapter());
    Hive.registerAdapter(MessageModelAdapter());
    Hive.registerAdapter(AttachmentModelAdapter());
    Hive.registerAdapter(UserProfileModelAdapter());

    await Hive.openBox<ThreadModel>('threads');
    await Hive.openBox<MessageModel>('messages');
    await Hive.openBox<UserProfileModel>('user_profile');
  }
}
