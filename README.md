# SayBar

Native macOS menu bar shell for hosting and supervising SayBar's speech-facing sibling services from one lightweight app surface.

## Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Usage](#usage)
- [Development](#development)
- [Configuration](#configuration)
- [Verification](#verification)
- [License](#license)

## Overview

SayBar is the standalone macOS app repository for the menu bar experience that sits in front of the speech and MCP services developed in sibling repositories. The current project now includes a native `MenuBarExtra` app target, a Settings scene, unit and UI test targets, and package wiring into `SpeakSwiftlyServer`. The app surface has moved beyond scaffolding and now hosts an embedded `SpeakSwiftlyServer` session through a dedicated app-owned controller.

### Motivation

This repository exists so the macOS app can evolve as its own product surface instead of being treated as an incidental wrapper around server code. Keeping the app in its own Xcode project makes it easier to build menu bar UX, settings, service supervision, diagnostics, and release flow in one place while still keeping the service and MCP implementations in their primary sibling repositories.

## Setup

1. Open [SayBar.xcodeproj](SayBar.xcodeproj) in Xcode.
2. Select the `SayBar` scheme.
3. Let Xcode resolve Swift package dependencies the first time you open the project.
4. Run the app on macOS from Xcode.

The current project signals show a macOS app target named `SayBar`, companion `SayBarTests` and `SayBarUITests` targets, and package dependencies centered on `SpeakSwiftlyServer`.

## Usage

The current app launches a menu bar extra and a Settings window from the `SayBar` scheme. The menu bar surface now shows embedded-session status, queue and playback summaries, and common service actions such as start, stop, restart, pause, resume, and queue clearing. The Settings window expands that with runtime, transport, playback, and diagnostics sections for the embedded `SpeakSwiftlyServer` session.

## Development

Use Xcode-aware workflows for app changes and keep the standalone `SayBar` repository as the source of truth for app development. For monorepo work in `../speak-to-user`, treat that checkout as a clean protected base and do SayBar-related feature work in a separate worktree rather than directly in the base checkout.

For the current embedded-session direction, see [docs/maintainers/embedded-session-integration-plan.md](docs/maintainers/embedded-session-integration-plan.md) for the maintainer-facing architecture and implementation plan.

For the controller-oriented future direction, including external attachment, launch-agent ownership options, and the possible later `SMAppService` packaging pivot, see [docs/maintainers/controller-architecture-options.md](docs/maintainers/controller-architecture-options.md).

Useful local commands:

```sh
xcodebuild -list -project SayBar.xcodeproj
xcodebuild -project SayBar.xcodeproj -scheme SayBar build
xcodebuild -project SayBar.xcodeproj -scheme SayBar test
```

## Configuration

- Primary app scheme: `SayBar`
- App bundle identifier: `com.galewilliams.SayBar`
- App marketing version: `0.1.0`
- App deployment target: macOS `15.6`
- Test targets: `SayBarTests`, `SayBarUITests`

The project also exposes package-managed schemes for the server package, but this repository's app-facing work should stay centered on the `SayBar` scheme unless a task explicitly targets package internals.

## Verification

For app work, prefer a scheme-based Xcode validation pass:

```sh
xcodebuild -project SayBar.xcodeproj -scheme SayBar build
xcodebuild -project SayBar.xcodeproj -scheme SayBar test
```

Keep heavy build and test commands serialized on this machine. Do not run concurrent Xcode or SwiftPM validation flows.

## License

SayBar is licensed under the terms in [LICENSE](LICENSE).
