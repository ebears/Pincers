# Pincers

A minimal, standalone chat application for OpenClaw agents. Connect to an OpenClaw gateway over WebSocket and chat with AI agents in real-time.

![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20Web-7C5CFF)
![Version](https://img.shields.io/badge/Version-1.0.0--beta.1-7C5CFF)

## Features

- **Real-time Chat** — Send messages and receive streaming responses over WebSocket
- **Thread Management** — Organize conversations into separate threads with full local history
- **Markdown Rendering** — Code blocks, syntax highlighting, and formatted text
- **File Support** — Drag-and-drop or pick files to share with agents
- **Device Identity** — Secure Ed25519-based device authentication
- **Dark Theme** — Material 3 design with violet accent

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- An OpenClaw gateway instance

### Installation

```bash
# Clone and enter the project
git clone https://github.com/your-org/pincers.git
cd pincers

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Desktop Builds

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

### Web

```bash
flutter build web
```

## Configuration

On first launch, enter your gateway credentials:

1. **Gateway URL** — The WebSocket endpoint of your OpenClaw gateway (e.g., `wss://gateway.example.com`)
2. **Auth Token** — Your authentication token for the gateway

Your device identity is automatically generated and stored securely.

## Architecture

```
lib/
├── main.dart                    # Entry point, window & storage initialization
├── app.dart                    # Root widget with Material 3 theme
├── core/                       # Theme, constants, utilities
│   ├── theme/                  # Colors, typography, Material 3 theme
│   └── utils/                  # Markdown and time formatting helpers
├── features/                   # Feature modules (Clean Architecture)
│   ├── auth/                  # Token entry, credential storage
│   ├── chat/                  # Messages, gateway WebSocket, streaming
│   ├── threads/               # Conversation list, thread CRUD
│   └── settings/              # App settings panel
├── shared/                    # Cross-cutting services
│   └── services/              # WebSocket, Hive storage, device identity
└── routing/                   # GoRouter configuration
```

### Key Technologies

| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| State | Riverpod |
| Storage | Hive (local) |
| Routing | GoRouter |
| WebSocket | web_socket_channel |
| Auth | Ed25519 (device identity) |

## Documentation

For OpenClaw Gateway Protocol v3 details, agent developers, and advanced configuration, see [AGENTS.md](./AGENTS.md).

## License

MIT
