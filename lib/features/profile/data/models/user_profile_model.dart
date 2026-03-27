import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 3)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  UserProfileModel({
    required this.id,
    required this.name,
  });
}
