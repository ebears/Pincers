import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile_model.dart';

class UserProfileRepository {
  static const _boxName = 'user_profile';
  static const _localUserId = 'local_user';

  Box<UserProfileModel> get _box => Hive.box<UserProfileModel>(_boxName);

  UserProfileModel? getProfile() => _box.get(_localUserId);

  Future<void> saveProfile(String name) async {
    final profile = UserProfileModel(id: _localUserId, name: name);
    await _box.put(_localUserId, profile);
  }

  Future<void> updateName(String name) async {
    final profile = _box.get(_localUserId);
    if (profile != null) {
      profile.name = name;
      await profile.save();
    }
  }

  bool hasProfile() => _box.containsKey(_localUserId);
}
