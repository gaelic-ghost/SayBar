# SayBar

Native macOS menu bar app for hosting and supervising an embedded `SpeakSwiftlyServer` session from one lightweight app surface.

## Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Usage](#usage)
- [Development](#development)
- [Configuration](#configuration)
- [Verification](#verification)
- [License](#license)

## Overview

SayBar is the standalone macOS app repository for the menu bar experience that sits in front of the speech runtime exposed through `SpeakSwiftlyServer`. The current app includes a native `MenuBarExtra`, a Settings scene, unit and UI test targets, and an app-owned `SpeakSwiftlyController` that starts and supervises one embedded `SpeakSwiftlyServer` session inside the app process.

### Motivation

This repository exists so the macOS app can evolve as its own product surface instead of being treated as incidental glue around server code. Keeping the app in its own Xcode project makes it easier to build the menu bar UX, settings UI, app-owned status vocabulary, diagnostics surfaces, and release flow in one place while still keeping server and MCP implementation details in their sibling repositories.

## Setup

1. Open [SayBar.xcodeproj](SayBar.xcodeproj) in Xcode.
2. Select the `SayBar` scheme.
3. Let Xcode resolve Swift package dependencies the first time you open the project.
4. Run the app on macOS from Xcode.

The current project includes these Xcode targets:

- `SayBar`
- `SayBarTests`
- `SayBarUITests`

The current package dependency surface in this repo is centered on `SpeakSwiftlyServer`.

## Usage

Launch the `SayBar` scheme to start the app. The menu bar surface shows the current embedded-session status, a compact status headline and detail string, queue summaries, and common operator actions such as start, stop, restart, pause, resume, and queue clearing.

Open Settings for deeper runtime, playback, transport, and diagnostics detail. The current implementation is embedded-session-first: SayBar hosts `SpeakSwiftlyServer` inside the app process rather than attaching to an external background service.

## Development

Use Xcode-aware workflows for app changes and keep the standalone `SayBar` repository as the source of truth for app development. For monorepo work in `../speak-to-user`, treat that checkout as a clean protected base and do SayBar-related feature work in a separate worktree rather than directly in the base checkout.

The maintainer docs are split intentionally:

- [docs/maintainers/embedded-session-integration-plan.md](docs/maintainers/embedded-session-integration-plan.md) describes the current embedded-session architecture and the implemented app-owned controller model.
- [docs/maintainers/controller-architecture-options.md](docs/maintainers/controller-architecture-options.md) captures the future decision space if SayBar later pivots toward external attachment or launch-agent-backed service ownership.

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
- Embedded server package: [`SpeakSwiftlyServer`](https://github.com/gaelic-ghost/SpeakSwiftlyServer)

The project also exposes package-managed schemes for the server package, but app-facing work in this repository should stay centered on the `SayBar` scheme unless a task explicitly targets package internals.

## Verification

For app work, prefer a scheme-based Xcode validation pass:

```sh
xcodebuild -project SayBar.xcodeproj -scheme SayBar build
xcodebuild -project SayBar.xcodeproj -scheme SayBar test
```

Keep heavy build and test commands serialized on this machine. Do not run concurrent Xcode or SwiftPM validation flows.

## License

SayBar is licensed under the terms in [LICENSE](LICENSE).
