# User Profile Design — Local Display Name

## Context

Pincers currently has no concept of a local user identity beyond a gateway token. On first launch, the user enters a gateway URL and bearer token to authenticate. The gateway sees a device identity but the app itself doesn't know or store anything about the human using it.

This spec adds a local display name — stored on-device only — shown in the settings panel. The gateway is not involved.

## What

- **Local display name** stored in Hive (encrypted local storage)
- **First-launch onboarding screen** collecting: name, gateway URL, token
- **Settings panel** displaying and allowing editing of the name
- **Auth guard** redirecting to `/setup` when no profile exists

## Architecture

### Storage

New Hive box: `'user_profile'` (typeId 3).

```
@HiveType(typeId: 3)
class UserProfileModel extends HiveObject {
  late String id;   // always 'local_user'
  late String name;
}
```

### Routing

Three routes:

| Path | Screen | Condition |
|------|--------|-----------|
| `/setup` | OnboardingPage | No profile in Hive |
| `/auth` | TokenEntryPage | Profile exists, not authenticated |
| `/` | ChatPage | Authenticated |

The router redirect logic (in priority order):

1. No profile → `/setup`
2. Profile exists, not authenticated, not on `/auth` → `/auth`
3. Authenticated and on `/auth` → `/`

### Onboarding Flow

`OnboardingPage` is a single form with three fields:

1. **Display Name** — text input, required, max 50 chars
2. **Gateway URL** — text input, required, WebSocket URL
3. **Bearer Token** — text input, required

On submit:

1. Validate all fields present
2. Perform auth handshake (same as current `validateAndSaveCredentials`)
3. If handshake succeeds → save profile to Hive → navigate to `/`
4. If handshake fails → show error, don't save profile

### Settings Panel

Add a "Profile" section to the existing `SettingsPanel`:

- Label: "Display Name"
- Value: current name from Hive
- Edit button → inline text field + save/cancel

### Data Flow

```
OnboardingPage
  ├── validateAndSaveCredentials()  // existing AuthNotifier method
  └── userProfileProvider.save(name) // new, after auth succeeds

SettingsPanel
  └── userProfileProvider.name       // read from Hive
```

## Files

### New

- `lib/features/profile/data/models/user_profile_model.dart`
- `lib/features/profile/data/repositories/user_profile_repository.dart`
- `lib/features/profile/presentation/providers/user_profile_provider.dart`
- `lib/features/profile/presentation/pages/onboarding_page.dart`

### Modified

- `lib/routing/app_router.dart` — add `/setup` route, update redirect
- `lib/shared/services/hive_service.dart` — register `UserProfileModel`, open `'user_profile'` box
- `lib/features/settings/presentation/widgets/settings_panel.dart` — add profile section

## Verification

1. Delete local Hive data (or use a fresh device) — app should redirect to `/setup`
2. On `/setup`, submit empty form → validation error shown
3. On `/setup`, submit valid URL + token but bad token → auth error shown
4. On `/setup`, submit valid name + URL + token → redirected to `/`
5. On `/`, open settings → profile section shows entered name
6. In settings, edit name → change is persisted and reflected
7. Sign out and sign back in (with same credentials) → name is preserved
