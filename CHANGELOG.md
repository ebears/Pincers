# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-beta.1] - 2026-03-27

### Added
- Agent avatar support in chat bubbles
- Verbose bubble mode for tool-call display
- User markdown support in chat input
- Session message event handling for tool-heavy responses
- Chat streaming protocol with deduplication strategy

### Changed
- Complete UX/visual redesign with Material 3 design system
- Migrated to M3 theme and drawer layout
- Typing indicator now scoped to active thread only
- Gateway connection initiates after auth finishes loading async credentials
- Agent identity provider initializes eagerly on page load

### Fixed
- Strip agent directive tokens from messages
- Connect gateway after auth finishes loading async credentials
- Remove unused user avatar
- Handle gateway event rename and improve error handling
- Use gateway-client/ui instead of webchat to avoid origin check

### Documentation
- Documented session.message event format and deduplication strategy
- Clarified chat streaming protocol and gotchas
- Rewrote AGENTS.md as concise agent reference

### Infrastructure
- Refreshed app icons across all platforms (Android, iOS, Web, Windows)
- Removed deprecated TypeScript device pairing and message handler files
