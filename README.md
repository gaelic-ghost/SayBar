# SayBar

Native macOS menu bar app for hosting and supervising an embedded `SpeakSwiftlyServer` runtime from one lightweight app surface.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Development](#development)
- [Repo Structure](#repo-structure)
- [Release Notes](#release-notes)
- [License](#license)

## Overview

SayBar is the standalone macOS app repository for the menu bar experience that sits in front of the speech runtime exposed through `SpeakSwiftlyServer`.

### Status

SayBar is in active early development as the standalone macOS app shell for the embedded `SpeakSwiftlyServer` runtime.

### What This Project Is

SayBar is a native macOS `MenuBarExtra` app that hosts, supervises, and presents the app-facing `SpeakSwiftlyServer` runtime from a lightweight menu bar and Settings surface.

### Motivation

This repository exists so the macOS app can evolve as its own product surface instead of being treated as incidental glue around server code. Keeping the app in its own Xcode project makes it easier to build the menu bar UX, settings UI, app-owned wording, diagnostics surfaces, and release flow in one place while still keeping server and MCP implementation details in their sibling repositories.

The current app architecture is intentionally thin:

- `SayBarApp` owns one long-lived `EmbeddedServer`
- the menu bar scene reads that `EmbeddedServer` directly for status and control actions
- the settings scene reads that same `EmbeddedServer` directly for version info and diagnostics
- the app keeps that app-owned observable model in SwiftUI state and requests graceful `land()` cleanup before quit

SayBar does not keep a second app-owned server controller anymore. The public `SpeakSwiftlyServer` library surface is already designed to be the app-facing `@Observable` model, so the app now treats `EmbeddedServer` as the source of truth for lifecycle, queue state, playback state, transport status, runtime configuration, and voice profile selection.

The menu bar scene now reads those observable properties directly. SayBar keeps only genuinely app-local state alongside the server object, such as transient action feedback and button busy flags.

`SpeakSwiftlyServer` now also exposes standalone-install layout and retained-log helper surfaces. SayBar is not adopting those helper paths yet. The current repo stays centered on the embedded-runtime contract until the product intentionally grows an app-managed standalone-server mode.

## Quick Start

SayBar is still a developer-facing app repo. To try it locally, open the Xcode project, select the `SayBar` scheme, let Xcode resolve packages, and run the app on macOS.

## Usage

Launch the `SayBar` scheme to start the app. The menu bar surface is intentionally compact:

- a status headline
- a detail line for the current warning, error, or runtime detail
- an eight-slot queue indicator for generation work
- one compact control row for resident-model power, playback or clipboard speech, and settings
- one picker row for voice profile selection and speech backend selection

Open Settings for deeper app and runtime diagnostics. The current settings surface shows the app version, autostart state, menu bar insertion preference, runtime summary values, transport details, and recent retained errors.

The current implementation is embedded-runtime-first: SayBar hosts `SpeakSwiftlyServer` inside the app process rather than attaching to an external background service.

Current lifecycle behavior is explicit in code now:

- launch starts the embedded runtime unless `--saybar-disable-autostart` is present
- quit requests `EmbeddedServer.land()` before allowing macOS termination to finish
- launch-only and relaunch-after-terminate UI tests both run with embedded autostart disabled so the app shell can be validated without pulling the full runtime into every UI test

## Development

Use Xcode-aware workflows for app changes and keep the standalone `SayBar` repository as the source of truth for app development. For monorepo work in `../speak-to-user`, treat that checkout as a clean protected base and do SayBar-related feature work in a separate worktree rather than directly in the base checkout.

### Setup

1. Open [SayBar.xcodeproj](SayBar.xcodeproj) in Xcode.
2. Select the `SayBar` scheme.
3. Let Xcode resolve Swift package dependencies the first time you open the project.
4. Run the app on macOS from Xcode.

The current project includes these Xcode targets:

- `SayBar`
- `SayBarTests`
- `SayBarUITests`

The current package dependency surface in this repo is centered on `SpeakSwiftlyServer`.

### Workflow

The maintainer docs are split intentionally:

- [docs/maintainers/README.md](docs/maintainers/README.md) is the maintainer-doc index and recommended reading order.
- [docs/maintainers/adr-0001-keep-embedded-session-architecture.md](docs/maintainers/adr-0001-keep-embedded-session-architecture.md) records the accepted direct-`EmbeddedServer` product baseline.
- [docs/maintainers/embedded-server-ui-architecture.md](docs/maintainers/embedded-server-ui-architecture.md) records the current app architecture around one app-owned `EmbeddedServer`.
- [docs/maintainers/accessibility-and-ui-automation-notes.md](docs/maintainers/accessibility-and-ui-automation-notes.md) captures the current accessibility and UI-automation state for the menu bar app.

Primary project configuration:

- Primary app scheme: `SayBar`
- App bundle identifier: `com.galewilliams.SayBar`
- App marketing version: `0.1.0`
- App deployment target: macOS `15.6`
- Test targets: `SayBarTests`, `SayBarUITests`
- Embedded server package: [`SpeakSwiftlyServer`](https://github.com/gaelic-ghost/SpeakSwiftlyServer)

The project also exposes package-managed schemes for the server package, but app-facing work in this repository should stay centered on the `SayBar` scheme unless a task explicitly targets package internals.

### Validation

For app work, prefer a scheme-based Xcode validation pass:

```sh
xcodebuild -list -project SayBar.xcodeproj
xcodebuild -project SayBar.xcodeproj -scheme SayBar build
xcodebuild -project SayBar.xcodeproj -scheme SayBar test
```

Keep heavy build and test commands serialized on this machine. Do not run concurrent Xcode or SwiftPM validation flows.

Use the repo-maintenance entrypoint for guidance, toolkit, and release-surface checks:

```sh
scripts/repo-maintenance/validate-all.sh
```

## Repo Structure

```text
.
├── SayBar/               # App source and assets
├── SayBarTests/          # Unit-style app tests
├── SayBarUITests/        # XCUITest coverage for launch and app shell behavior
├── SayBar.xcodeproj/     # Xcode-managed project and package resolution
├── docs/maintainers/     # Architecture, ADR, and maintainer notes
└── scripts/repo-maintenance/
    ├── validate-all.sh   # Local validation entrypoint used by CI
    ├── sync-shared.sh    # Shared-maintenance sync entrypoint
    └── release.sh        # Release workflow entrypoint
```

## Release Notes

Use [ROADMAP.md](ROADMAP.md) and GitHub releases to track notable shipped changes. Tagged releases should use `scripts/repo-maintenance/release.sh` so local validation, tagging, push, and GitHub release steps stay on the same repo-owned path.

## License

SayBar is licensed under the terms in [LICENSE](LICENSE).
