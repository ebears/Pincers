# Pincers — Design Document

> A minimal, standalone chat app for OpenClaw agents.

---

## 1. Overview

### What It Is
**Pincers** is a clean, focused chat interface for your OpenClaw agent. Think of it as a personal, no-frills ChatGPT/Claude web app — built specifically for you, connecting directly to your gateway.

### Why It Exists
OpenClaw's current interfaces (Matrix, Discord, CLI) are powerful but channel-oriented. Sometimes you just want a quiet, private space to chat with your agent without the overhead of chat platforms. Pincers is that space.

### Design Philosophy
- **Distraction-free.** No channels, no servers, no DMs with other people. Just you and your bot.
- **Conversation-first.** Everything serves the chat. UI chrome is minimal.
- **Local-first.** Conversation history lives on-device (Hive). No server-side storage required.
- **Offline-resilient.** You can load past conversations without an internet connection (just can't send messages).
- **Cross-platform.** One codebase, running natively on Android, iOS, Windows, Linux, and Web.

### v1 Scope (Iron Triangle)
| In | Out |
|----|-----|
| Chat with agent | Admin panel |
| New conversation | Channel switching |
| Resume conversation | Multi-agent support |
| Thread history (local) | Cloud sync |
| File/image sharing | Voice/audio |

---

## 2. Design Language

### Aesthetic Direction
**Minimalist sanctuary.** Inspired by the clean spacing of iMessage, the focus of ChatGPT's web UI, and the warmth of a well-designed productivity app. Not sterile — warm minimalism. Subtle personality without clutter.

### Color Palette
```
--bg-primary:       #0D0D0F        /* near-black, slightly warm */
--bg-secondary:     #161618        /* sidebar, panels */
--bg-tertiary:      #1E1E21        /* input area, cards */
--bg-hover:         #262629        /* hover states */
--border:           #2A2A2D        /* subtle dividers */
--text-primary:     #ECEDEE        /* main text */
--text-secondary:   #8B8B92        /* timestamps, meta */
--text-muted:       #5C5C63        /* placeholders */
--accent:           #7C5CFF        /* primary accent — violet */
--accent-hover:     #9070FF        /* accent hover */
--accent-glow:      rgba(124, 92, 255, 0.15)  /* subtle glow */
--user-bubble:      #7C5CFF        /* your messages */
--bot-bubble:       #1E1E21        /* bot messages */
--success:          #34D399        /* online status */
--error:            #F87171        /* errors */
--typing:           #8B8B92        /* typing indicator */
```

### Typography
- **Primary:** Inter (Google Fonts) — clean, readable, modern
- **Monospace:** JetBrains Mono — for code blocks
- **Scale:**
  - Chat messages: 15px / 1.6 line-height
  - Timestamps: 12px
  - Thread titles: 14px / 500 weight
  - Input: 15px

### Spacing System
- Base unit: 4px
- Component padding: 12px / 16px / 20px
- Chat bubble padding: 12px 16px
- Section gaps: 24px
- Border radius: 12px (bubbles), 8px (buttons/inputs), 24px (sidebar)

### Motion Philosophy
- **Subtle and purposeful.** Motion should guide attention, not entertain.
- Message appear: `opacity 0→1, translateY 8px→0, 200ms ease-out`
- Thread list items: `opacity 0→1, 150ms ease-out, staggered 30ms`
- Typing indicator: Three dots with `scale 0.8→1, 600ms infinite, staggered 150ms`
- No bouncy/playful animations — keep it calm and focused.

---

## 3. Layout & Structure

### Screen Composition
```
┌─────────────────────────────────────────────────────────┐
│  [≡]  Pincers                         [@thom] [⚙️]      │  ← Header (48px)
├──────────────┬──────────────────────────────────────────┤
│              │                                          │
│  Threads     │         Chat Area                       │
│  ─────────   │         ─────────                       │
│  Today       │   ┌─────────────────┐                    │
│  • Chat 1    │   │ Bot message     │                    │
│  • Chat 2    │   └─────────────────┘                    │
│              │                                          │
│  Yesterday   │         ┌─────────────────────────┐     │
│  • Chat 3    │         │ User message            │     │
│              │         └─────────────────────────┘     │
│  This Week   │                                          │
│  • Chat 4    │         ┌─────────────────┐              │
│  ...         │         │ Bot response    │              │
│              │         └─────────────────┘              │
│  [+ New]     │                                          │
│              │  ─────────────────────────────────────── │
│              │  [📎] [                        ] [Send ➤] │  ← Input (64px)
│              │                                          │
└──────────────┴──────────────────────────────────────────┘
   Sidebar            Chat (centered, max-width 720px)
   (240px,            with generous side margins
    collapsible)
```

### Responsive Strategy
- **≥1024px:** Full layout with sidebar visible
- **768–1023px:** Sidebar collapsed by default, hamburger to reveal
- **<768px:** Sidebar hidden, full-screen chat, swipe-right to reveal threads

### Chat Area Details
- Messages centered in a **max-width 720px** column
- Generous vertical spacing between messages (24px)
- Bot messages aligned left, user messages aligned right
- Timestamps shown on first message of each group, then hidden until time gap >5min

---

## 4. Features & Interactions

### 4.1 Chat with Agent

**Send a message:**
1. User types in input area (textarea, auto-grows up to 6 lines)
2. Press Enter or click Send
3. Message appears immediately in chat as user bubble (optimistic)
4. Input clears, input area shrinks back
5. Typing indicator appears (three animated dots)
6. Response streams in token-by-token
7. Full response rendered, timestamp added

**Code blocks:**
- Rendered with syntax highlighting (highlight.js or Shiki)
- Copy button on hover
- Language label in top-right corner
- Max-height with scroll for long blocks

**Markdown support:**
- Bold, italic, inline code, links, lists
- No headings in chat bubbles (keeps it conversational)

**File/image attachments:**
- Click 📎 icon → file picker opens
- Drag-and-drop supported anywhere in chat area
- Files sent as base64 to gateway (same as Matrix)
- Images render inline, click to expand (lightbox)
- Unsupported file types show as text preview + download link

**Error states:**
- Network error: Red banner under input — "Couldn't send. Tap to retry."
- Gateway unreachable: Typing indicator replaced with "Reconnecting..." (auto-retries)
- Auth failure: Redirect to token entry screen

### 4.2 Start New Conversation

**Trigger:** Click **[+ New]** button at bottom of thread list (always visible)

**Behavior:**
1. Current thread deselects (chat area shows empty state if no thread selected)
2. New thread created with placeholder title: "New conversation"
3. Thread appears at top of "Today" section with subtle highlight
4. Chat area clears and shows welcome state (not empty — see below)
5. Cursor auto-focuses in input area

**Welcome state (first time or no thread selected):**
```
         🦞
    Hi, I'm Aralobster.
    
    I'm your personal assistant — here to help,
    chat, and maybe cause some cheerful chaos.
    
    What would you like to do?
```
With three subtle suggested prompts below:
- "Help me with a task"
- "Tell me something interesting"
- "Start a project"

### 4.3 Resume Conversation

**Thread list organization:**
- **Today** — threads created today
- **Yesterday** — threads from yesterday
- **This Week** — threads from this week (collapsed by default)
- **Earlier** — older threads (collapsed by default)

**Thread item shows:**
- First line of the conversation (truncated to 1 line)
- Timestamp: "2:34 PM" for today/yesterday, "Mar 20" for dates

**Behavior on click:**
1. Thread highlighted in sidebar
2. Chat area fades out (150ms) and loads messages
3. Chat area fades in with full thread history
4. Scroll to bottom (latest message)
5. If thread has no messages, show empty state with just the title

**Thread title:**
- Generated from first user message (truncated to 40 chars)
- User can rename by clicking the title in chat area header

### 4.4 Thread Management

**Delete thread:**
- Hover thread item → trash icon appears
- Click trash → confirmation toast: "Delete conversation?" [Cancel] [Delete]
- Delete removes from IndexedDB, updates sidebar

**Clear conversation (keep thread):**
- In chat area header, three-dot menu → "Clear messages"
- Clears messages but keeps thread in list

---

## 5. Component Inventory

### Header
- **Default:** Logo left, user avatar + settings icon right
- **With sidebar hidden (mobile):** Hamburger menu added left of logo
- Height: 48px, border-bottom with `--border`

### Sidebar
- **Default:** 240px wide, `--bg-secondary`
- **Collapsed:** Width 0, hidden off-screen
- **Thread item states:**
  - Default: `--bg-secondary`
  - Hover: `--bg-hover`
  - Selected: `--bg-tertiary` with left border accent (`--accent`, 3px)

### ThreadGroupHeader
- Section label (Today, Yesterday, etc.)
- 12px, `--text-secondary`, uppercase, letter-spacing 0.05em
- Collapsible with chevron

### ChatBubble (User)
- Background: `--user-bubble`
- Text: white
- Border-radius: 12px, top-right 4px
- Max-width: 80% of chat column

### ChatBubble (Bot)
- Background: `--bot-bubble`
- Text: `--text-primary`
- Border: 1px `--border`
- Border-radius: 12px, top-left 4px
- Max-width: 80% of chat column

### TypingIndicator
- Three dots, `--typing` color
- Appears in a bot-style bubble
- Animation: scale 0.8→1, staggered 150ms, 600ms loop

### InputArea
- Background: `--bg-tertiary`
- Border: 1px `--border`
- Border-radius: 24px (pill shape)
- Contains: attach button (left), textarea (center), send button (right)
- Textarea auto-grows 1–6 lines

### AttachmentPreview
- Thumbnail for images (64px, rounded)
- Filename + size for documents
- X button to remove before sending

### EmptyState (no thread selected)
- Centered in chat area
- Bot avatar (large, 64px)
- Bot name
- Bot tagline/personal message
- Three suggested prompts (subtle buttons)

### ErrorBanner
- Background: `--error` with 15% opacity
- Text: `--error`
- Appears below input area, above keyboard (mobile)
- Dismissible with X

### SettingsPanel
- Slide-in panel from right (320px wide)
- Sections: Account (token display), Appearance (future), About

---

## 6. Technical Approach

### Stack
- **Framework:** Flutter (Dart)
- **State:** Riverpod (flutter_riverpod, riverpod_annotation)
- **Architecture:** Feature-first Clean Architecture
- **Storage:** Hive (hive_flutter) — local NoSQL, no native dependencies
- **Markdown:** flutter_markdown with syntax highlighting
- **WebSocket:** web_socket_channel
- **Target platforms:** Android, iOS, Windows, Linux, Web (Flutter cross-platform)

### Architecture Philosophy
Clean Architecture with feature-first organization. Each feature is a self-contained unit with its own data, domain, and presentation layers. Dependencies flow inward — presentation depends on domain, domain on data. No feature can reach into another feature's internals.

### Project Structure
```
pincers/
├── lib/
│   ├── main.dart                    # app entry point
│   ├── app.dart                     # MaterialApp configuration
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart      # color palette as Color constants
│   │   │   ├── app_typography.dart  # text styles
│   │   │   └── app_theme.dart       # ThemeData build
│   │   ├── constants/
│   │   │   └── app_constants.dart   # spacing, radii, durations
│   │   └── utils/
│   │       ├── time_utils.dart      # timestamp formatting
│   │       └── markdown_utils.dart  # markdown rendering helpers
│   │
│   ├── features/
│   │   ├── chat/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── message_model.dart
│   │   │   │   │   └── attachment_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── chat_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       └── message.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── chat_provider.dart       # messages state
│   │   │       │   ├── gateway_provider.dart    # WebSocket connection
│   │   │       │   └── typing_provider.dart     # typing indicator state
│   │   │       ├── widgets/
│   │   │       │   ├── chat_area.dart
│   │   │       │   ├── chat_bubble.dart
│   │   │       │   ├── typing_indicator.dart
│   │   │       │   └── input_area.dart
│   │   │       └── pages/
│   │   │           └── chat_page.dart
│   │   │
│   │   ├── threads/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── thread_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── threads_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       └── thread.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── threads_provider.dart
│   │   │       ├── widgets/
│   │   │       │   ├── thread_list.dart
│   │   │       │   ├── thread_item.dart
│   │   │       │   └── thread_group_header.dart
│   │   │       └── pages/
│   │   │           └── threads_page.dart
│   │   │
│   │   ├── settings/
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── settings_provider.dart
│   │   │       ├── widgets/
│   │   │       │   └── settings_panel.dart
│   │   │       └── pages/
│   │   │           └── settings_page.dart
│   │   │
│   │   └── auth/
│   │       └── presentation/
│   │           ├── providers/
│   │           │   └── auth_provider.dart
│   │           └── pages/
│   │               └── token_entry_page.dart
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── app_header.dart
│   │   │   ├── empty_state.dart
│   │   │   └── error_banner.dart
│   │   └── services/
│   │       ├── hive_service.dart    # Hive box initialization
│   │       └── websocket_service.dart  # WebSocket connection manager
│   │
│   └── routing/
│       └── app_router.dart          # GoRouter configuration
│
├── assets/
│   └── images/
│       └── aralobster.png           # bot avatar
├── pubspec.yaml
└── flutter_*
```

### Data Layer

**Hive boxes:**

```dart
// threads box
@HiveType(typeId: 0)
class ThreadModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) DateTime createdAt;
  @HiveField(3) DateTime updatedAt;
  @HiveField(4) String? sessionId;
}

// messages box
@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String threadId;
  @HiveField(2) String role;        // 'user' | 'bot'
  @HiveField(3) String content;
  @HiveField(4) List<AttachmentModel> attachments;
  @HiveField(5) DateTime createdAt;
}
```

**Repository pattern:**
- `ThreadsRepository` — CRUD operations on threads Hive box
- `ChatRepository` — CRUD operations on messages Hive box, WebSocket send/receive

### State Management (Riverpod)

**Core providers:**

```dart
// Gateway connection state
@riverpod
class GatewayConnection extends _$GatewayConnection {
  WebSocketChannel? _channel;
  
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);
  
  Future<void> connect(String gatewayUrl, String token) async { ... }
  Future<void> send(String method, Map<String, dynamic> params) async { ... }
  void disconnect() { _channel?.sink.close(); }
}

// Current chat messages
@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  List<MessageModel> build() => [];
  
  void addUserMessage(String content) { ... }
  void addBotMessage(String content) { ... }
  void clear() { state = []; }
}

// Thread list
@riverpod
class ThreadList extends _$ThreadList {
  @override
  List<ThreadModel> build() => [];
  
  Future<void> loadThreads() async { ... }
  Future<void> createThread() async { ... }
  Future<void> deleteThread(String id) async { ... }
}
```

**Dependency flow:**
- `ChatMessagesProvider` depends on `GatewayConnectionProvider` (to send messages)
- `ThreadsProvider` depends on `ChatMessagesProvider` (to know when thread was last active)

### Gateway Connection

**WebSocket endpoint:**
```
ws://<gateway-url>/rpc
```

**Auth:** Bearer token in connection header (same as existing OpenClaw auth)

**Message protocol:** JSON-RPC 2.0

**Key methods:**
- `session.start` — start a new agent session
- `session.send` — send a message
- `session.stream` — receive streaming response
- `session.history` — load message history

**Connection flow:**
1. On app launch, check for stored gateway token
2. If no token → show `TokenEntryPage`
3. If token → connect WebSocket, store session ID
4. On disconnect → show reconnecting UI with exponential backoff
5. On token invalid → clear token, redirect to `TokenEntryPage`

### Platform-Specific Considerations

**Android:**
- Request `INTERNET` permission (standard)
- Use `path_provider` for Hive storage location
- Handle back button for thread drawer

**Desktop (Windows/Linux):**
- Window minimum size: 800x600
- Keyboard shortcuts: Ctrl+N (new thread), Ctrl+W (close thread), Escape (close drawer/panel)

**Web:**
- Run in SPA mode (`flutter run -d chrome`)
- WebSocket handled natively in browser
- Hive uses IndexedDB on web

**iOS:**
- Standard permissions, no special requirements

### Auth Flow
1. On first launch, prompt for gateway token
2. Validate token by attempting WebSocket connection
3. Store token securely via `flutter_secure_storage` (mobile) or encrypted in Hive (desktop/web)
4. On app start, attempt connection with stored token
5. If connection fails, clear token and re-prompt

### Environment / Build Config
```yaml
# pubspec.yaml (relevant sections)
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  flutter_markdown: ^0.7.3
  web_socket_channel: ^3.0.1
  flutter_secure_storage: ^9.2.2
  go_router: ^14.6.2
  path_provider: ^2.1.4

dev_dependencies:
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
```

---

## 7. Future Considerations (Out of Scope for v1)

- **Cloud sync** — encrypt and sync threads across devices (self-hosted or iCloud)
- **Multi-agent** — switch between different OpenClaw agents
- **Voice/audio** — voice input, text-to-speech for responses
- **Themes** — light mode, custom accent colors
- **Keyboard shortcuts** — vim-style navigation for desktop
- **Shared threads** — invite someone to a bot conversation
- **Widgets** — home screen widgets for Android
- **Push notifications** — native notifications when bot is responding (mobile)

---

## 8. Open Questions

1. **Session persistence on gateway:** Does the gateway persist sessions after WebSocket disconnects? Need to verify so refresh/resume works correctly.
2. **Token storage security:** Is `sessionStorage` appropriate, or should we encrypt + use `localStorage` with a user-set password?
3. **File size limits:** What are the gateway's limits on attachments? Should we show a warning for large files?
4. **Message format:** Does gateway accept/store markdown, or does it store plain text and we render on display?
5. **Thread title sync:** Should thread titles sync back to the gateway (so other clients see the same title)?

---

*Last updated: 2026-03-25*
