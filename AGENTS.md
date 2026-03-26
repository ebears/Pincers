# Pincers — Agent Guide

> Minimal chat UI for OpenClaw agents. Flutter (Dart), cross-platform.

## Quick Start

```bash
flutter pub get          # install dependencies
flutter analyze          # lint
flutter build windows    # build (or: linux, web, apk, ios)
flutter run -d windows   # run debug
```

## What This Is

Pincers is a standalone chat app that connects to an [OpenClaw](https://github.com/openclaw/openclaw) gateway over WebSocket. It provides a simple conversation UI — send messages, see streaming responses, manage threads. All conversation history is stored locally (Hive). No server-side chat storage.

## Architecture

**Stack:** Flutter + Riverpod (state) + Hive (local storage) + WebSocket

**Structure:** Feature-first Clean Architecture:
```
lib/
├── core/          # theme, constants, utils
├── features/
│   ├── auth/      # token entry, credential storage (flutter_secure_storage)
│   ├── chat/      # messages, gateway connection, streaming, input
│   ├── threads/   # conversation list, sidebar, thread CRUD
│   └── settings/  # settings panel
├── shared/        # services (websocket, hive, device identity), shared widgets
└── routing/       # GoRouter config
```

Each feature has `data/` (models, repositories), `domain/` (entities), and `presentation/` (providers, widgets, pages) layers.

## OpenClaw Gateway Protocol (v3)

Pincers speaks the OpenClaw WebSocket protocol v3. Key concepts:

### Connection Flow
1. Connect to `wss://<gateway-host>` via WebSocket
2. Gateway sends `connect.challenge` event with `{nonce, ts}`
3. Client sends `connect` request with auth token, device identity, and signed nonce
4. Gateway responds with `hello-ok` containing `connId`, auth info, scopes

### Device Identity (Required)
The gateway **strips all scopes** from device-less clients using token auth. Pincers generates and persists an Ed25519 keypair (`DeviceIdentityService`):
- **Device ID:** `hex(SHA256(publicKey))`
- **Signature payload:** `v2|deviceId|clientId|clientMode|role|scopes|signedAtMs|token|nonce`
- Keypair stored in `flutter_secure_storage`, generated on first launch
- Without device identity, `sessions.create` and `chat.send` fail with "missing scope: operator.write"

### Frame Format
- **Request:** `{type:"req", id, method, params}`
- **Response:** `{type:"res", id, ok:true, payload:{...}}` or `{type:"res", id, ok:false, error:{code, message}}`
- **Event:** `{type:"event", event:"<name>", payload:{...}}`

### Key Methods
| Method | Purpose |
|--------|---------|
| `connect` | Handshake (sent after connect.challenge) |
| `sessions.create` | Create a chat session (returns `{key}`) |
| `sessions.list` | List existing sessions |
| `sessions.messages.subscribe` | Subscribe the current connection to all chat events for a session — params: `{key: sessionKey}` (required for multi-run tool responses — see Gotchas) |
| `chat.send` | Send a user message to a session |

### Chat Streaming
Bot responses arrive as `chat` events:
- `state:"delta"` — incremental token content (streamed)
- `state:"final"` — complete response (final message). May omit `message` when the agent emits a silent reply (no content for the client).
- `state:"error"` / `state:"aborted"` — failure states

Content can be a string or array of `{type:"text", text:"..."}` blocks. Final content may carry a trailing incomplete XML tag (e.g. `</`) from LLM streaming artifacts — strip any `<[^>]*$` suffix before display.

### Session Message Events
When subscribed via `sessions.messages.subscribe`, the gateway also delivers `session.message` events for every message saved to the session (user echoes, tool calls, final answers). These are the **only** delivery path for multi-run tool responses — the originating `chat.send` run ends with a silent `final`.

`session.message` payload shape:
```json
{
  "sessionKey": "agent:main:dashboard:<uuid>",
  "messageId": "40acd4aa",
  "messageSeq": 3,
  "message": {
    "role": "assistant",
    "content": [
      { "type": "thinking", "thinking": "..." },
      { "type": "text", "text": "The actual response shown to the user." }
    ],
    "stopReason": "stop",
    "timestamp": 1774552698195
  },
  "session": { ... }
}
```

Content block types seen in `session.message`:
- `type:"text"` — visible response text (display this)
- `type:"thinking"` — internal chain-of-thought (skip)
- `type:"toolCall"` — tool invocation with `id`, `name`, `arguments` (skip or show as verbose)

`stopReason` values: `"stop"` (final answer), `"toolUse"` (more tool calls pending).  
Display only `role:"assistant"` + `stopReason:"stop"` messages that contain at least one `type:"text"` block.

### Client Identity
- **client.id:** `cli` (from `GATEWAY_CLIENT_IDS` enum)
- **client.mode:** `backend` (from `GATEWAY_CLIENT_MODES` enum)
- **role:** `operator`
- **scopes:** `["operator.read", "operator.write"]`

## Key Files

| File | What It Does |
|------|-------------|
| `lib/shared/services/websocket_service.dart` | WebSocket connection, protocol handshake, request/response tracking, event stream |
| `lib/shared/services/device_identity_service.dart` | Ed25519 keypair generation, nonce signing for device auth |
| `lib/features/chat/presentation/providers/gateway_provider.dart` | Gateway state (connect/disconnect/reconnect), exposes `sendRequest()` and `events` stream |
| `lib/features/chat/presentation/providers/chat_provider.dart` | Message send/receive, session creation, streaming delta assembly, `sessions.messages.subscribe` call, `session.message` event handler with dedup |
| `lib/features/chat/presentation/widgets/chat_area.dart` | Main chat UI — message list, typing indicator, error banner, retry |
| `lib/features/auth/presentation/providers/auth_provider.dart` | Token + gateway URL storage, validation handshake |
| `lib/features/threads/presentation/providers/threads_provider.dart` | Thread CRUD, selection state, session ID mapping |

## Design Tokens

- **Colors:** Dark theme — `#0D0D0F` bg, `#7C5CFF` accent (violet), `#1E1E21` bot bubbles
- **Typography:** Inter (UI), JetBrains Mono (code blocks), 15px chat text
- **Spacing:** 4px base unit. Bubbles: 12px 16px padding, 12px radius
- **Motion:** Subtle — 200ms ease-out for messages, no bouncy animations

## Gotchas

- **`chat.send` must not include `deliver: true`** — when set, the gateway routes the response to the session's last external channel (WhatsApp, Telegram, etc.) and sends Pincers only an empty `final` with no content. Omit `deliver` so the gateway responds via the internal WebSocket channel.
- **`sessions.messages.subscribe` is required for tool responses** — `chat.send` only auto-routes events for the single run it initiates. When the agent uses tools, the tool call progress and final answer arrive in separate runs delivered only to subscribed connections. Without subscribing, Pincers receives a silent `final` and shows nothing. Subscribe after getting/creating the session (`{key: sessionKey}`), and re-subscribe after each reconnection (subscriptions are per-connection, cleared on disconnect). **Deduplication:** non-streaming `chat` finals are suppressed when subscribed (same content arrives via `session.message`); a short-lived content-fingerprint cache prevents `session.message` from re-showing content already rendered by streaming `chat` deltas.
- **Silent replies** — the gateway may send a `final` event with no `message` field. This is intentional: the agent emitted a suppression token and the gateway withheld the output. Pincers logs these and shows nothing.
- **Session labels** use `pincers-<threadId>` (UUID) to avoid collisions. If a label exists, the code falls back to `sessions.list` to find and reuse it.
- **Auth validation** (token entry screen) does a throwaway connect handshake to verify credentials before saving — this does NOT use device identity since it only needs to verify the token is accepted.
- **Reconnection** is automatic with exponential backoff (1s → 30s max). The WebSocket service handles this internally.
- **Hive** stores threads and messages locally. Boxes are initialized in `HiveService` at app startup.
- **Platform WebSocket:** Uses conditional imports (`websocket_channel_factory_io.dart` / `_stub.dart`) for platform-specific WebSocket creation.