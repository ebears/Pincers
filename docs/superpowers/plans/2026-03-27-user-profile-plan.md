# User Profile Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local display name collected on first launch and shown in settings.

**Architecture:** New `profile` feature following the existing feature-first pattern (data/domain/presentation layers). Profile stored in Hive. Onboarding screen combines name entry with gateway URL/token entry. Existing auth guard extended to redirect to `/setup` when no profile exists.

**Tech Stack:** Flutter, Hive, Riverpod, GoRouter

**TypeId reservation:** `typeId: 3` for `UserProfileModel` (typeIds 0, 1, 2 are already used).

---

## File Map

### New Files
| File | Responsibility |
|------|----------------|
| `lib/features/profile/data/models/user_profile_model.dart` | Hive model for local user profile |
| `lib/features/profile/data/repositories/user_profile_repository.dart` | CRUD operations on the profile Hive box |
| `lib/features/profile/presentation/providers/user_profile_provider.dart` | Riverpod notifier for profile state |
| `lib/features/profile/presentation/pages/onboarding_page.dart` | Combined name + gateway URL + token form |

### Modified Files
| File | Change |
|------|--------|
| `lib/routing/app_router.dart` | Add `/setup` route; update redirect to check profile first |
| `lib/shared/services/hive_service.dart` | Register `UserProfileModel` (typeId 3); open `'user_profile'` box |
| `lib/features/settings/presentation/widgets/settings_panel.dart` | Add editable name section |

---

## Task 1: UserProfileModel and Hive Registration

**Files:**
- Create: `lib/features/profile/data/models/user_profile_model.dart`
- Modify: `lib/shared/services/hive_service.dart`

- [ ] **Step 1: Create UserProfileModel**

```dart
// lib/features/profile/data/models/user_profile_model.dart

import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 3)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  UserProfileModel({required this.id, required this.name});
}
```

- [ ] **Step 2: Run build_runner to generate adapter**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `user_profile_model.g.dart` generated

- [ ] **Step 3: Modify HiveService — register adapter and open box**

In `HiveService.init()`, after `Hive.registerAdapter(ThreadModelAdapter())`:
```dart
Hive.registerAdapter(UserProfileModelAdapter());
await Hive.openBox<UserProfileModel>('user_profile');
```

- [ ] **Step 4: Verify Hive initializes cleanly**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/data/models/user_profile_model.dart lib/shared/services/hive_service.dart
git commit -m "feat(profile): add UserProfileModel with typeId 3"
```

---

## Task 2: UserProfileRepository

**Files:**
- Create: `lib/features/profile/data/repositories/user_profile_repository.dart`

- [ ] **Step 1: Create UserProfileRepository**

```dart
// lib/features/profile/data/repositories/user_profile_repository.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile_model.dart';

class UserProfileRepository {
  static const _boxName = 'user_profile';
  static const _localUserId = 'local_user';

  Box<UserProfileModel> get _box => Hive.box<UserProfileModel>(_boxName);

  UserProfileModel? getProfile() {
    return _box.get(_localUserId);
  }

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

  bool hasProfile() {
    return _box.containsKey(_localUserId);
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/data/repositories/user_profile_repository.dart
git commit -m "feat(profile): add UserProfileRepository with basic CRUD"
```

---

## Task 3: UserProfileProvider

**Files:**
- Create: `lib/features/profile/presentation/providers/user_profile_provider.dart`

- [ ] **Step 1: Create UserProfileNotifier**

```dart
// lib/features/profile/presentation/providers/user_profile_provider.dart

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

  UserProfileState({this.name, this.isLoaded = false});

  UserProfileState copyWith({String? name, bool? isLoaded}) {
    return UserProfileState(
      name: name ?? this.name,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserProfileRepository _repo;

  UserProfileNotifier(this._repo) : super(UserProfileState()) {
    _load();
  }

  void _load() {
    final profile = _repo.getProfile();
    state = UserProfileState(name: profile?.name, isLoaded: true);
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
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/providers/user_profile_provider.dart
git commit -m "feat(profile): add UserProfileNotifier with hasProfile check"
```

---

## Task 4: OnboardingPage

**Files:**
- Create: `lib/features/profile/presentation/pages/onboarding_page.dart`

- [ ] **Step 1: Create OnboardingPage**

Follow the pattern from `TokenEntryPage`. Fields: name, gatewayUrl, token. On submit:
1. Validate all fields non-empty
2. Call `authNotifier.validateAndSaveCredentials(gatewayUrl, token)`
3. On success: `userProfileNotifier.save(name)` then navigate to `/`

```dart
// lib/features/profile/presentation/pages/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gatewayUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _gatewayUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).validateAndSaveCredentials(
            _gatewayUrlController.text.trim(),
            _tokenController.text.trim(),
          );
      await ref.read(userProfileProvider.notifier).save(
            _nameController.text.trim(),
          );
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome to Pincers',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 50,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gatewayUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Gateway URL',
                      hintText: 'wss://gateway.example.com',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Bearer Token',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: No errors related to OnboardingPage

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/pages/onboarding_page.dart
git commit -m "feat(profile): add OnboardingPage with name, URL, token form"
```

---

## Task 5: Router — /setup Route and Redirect Logic

**Files:**
- Modify: `lib/routing/app_router.dart`

- [ ] **Step 1: Read current router**

Run: `cat lib/routing/app_router.dart`

- [ ] **Step 2: Update imports** — add OnboardingPage and userProfileProvider

- [ ] **Step 3: Add /setup route**

```dart
GoRoute(path: '/setup', builder: (context, state) => const OnboardingPage()),
```

- [ ] **Step 4: Update redirect — profile check first**

Replace the redirect callback with:

```dart
redirect: (context, state) {
  final authState = ref.read(authProvider);
  final hasProfile = ref.read(userProfileProvider.notifier).hasProfile;

  if (authState.isLoading) return null;

  // No profile yet → onboarding
  if (!hasProfile && state.matchedLocation != '/setup') {
    return '/setup';
  }

  // Profile exists, not authenticated, not on /auth → /auth
  final isAuth = state.matchedLocation == '/auth';
  if (!authState.isAuthenticated && !isAuth) return '/auth';

  // Authenticated and on /auth or /setup → /
  if (authState.isAuthenticated && (isAuth || state.matchedLocation == '/setup')) {
    return '/';
  }

  return null;
},
```

Also add `refreshListenable` for `userProfileProvider` so re-auth doesn't get stuck.

- [ ] **Step 5: Verify it compiles**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/routing/app_router.dart
git commit -m "feat(profile): add /setup route and profile-based redirect"
```

---

## Task 6: Settings Panel — Name Section

**Files:**
- Modify: `lib/features/settings/presentation/widgets/settings_panel.dart`

- [ ] **Step 1: Read current SettingsPanel**

Run: `cat lib/features/settings/presentation/widgets/settings_panel.dart`

- [ ] **Step 2: Add profile section**

Inject `userProfileProvider`. Add a "Display Name" row in the settings list:
- Shows current name (or "Not set")
- Edit button → shows inline TextField + save/cancel
- On save: calls `userProfileNotifier.updateName(name)`

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/presentation/widgets/settings_panel.dart
git commit -m "feat(profile): add display name section to settings panel"
```

---

## Verification

Run each of these manually:

1. **Clean state:** Delete or rename the Hive profile box (`hive delete box user_profile`) — app should redirect to `/setup`
2. **Empty form:** Submit empty form → validation errors shown
3. **Bad credentials:** Submit valid name + URL, bad token → auth error shown
4. **Happy path:** Submit name + valid URL + valid token → redirected to `/`
5. **Name in settings:** Open settings → display name section shows entered name
6. **Edit name:** Change name in settings → change persisted
7. **Sign out / sign back in:** With same Hive data, name is preserved
