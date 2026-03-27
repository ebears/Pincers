import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider((ref) => UserProfileRepository());

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier(ref.read(userProfileRepositoryProvider));
});

class UserProfileState {
  final String? name;
  final bool isLoaded;

  const UserProfileState({this.name, this.isLoaded = false});

  UserProfileState copyWith({String? name, bool? isLoaded}) {
    return UserProfileState(
      name: name ?? this.name,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserProfileRepository _repo;

  UserProfileNotifier(this._repo) : super(const UserProfileState()) {
    _load();
  }

  void _load() {
    final profile = _repo.getProfile();
    state = UserProfileState(
      name: profile?.name,
      isLoaded: true,
    );
  }

  Future<void> save(String name) async {
    await _repo.saveProfile(name);
    state = state.copyWith(name: name);
  }

  Future<void> updateName(String name) async {
    await _repo.updateName(name);
    state = state.copyWith(name: name);
  }

  bool get hasProfile => _repo.hasProfile();
}
