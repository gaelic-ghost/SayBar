# SayBar

SayBar is a macOS `MenuBarExtra` app intended to host and control the local SpeakSwiftly speech server and MCP components from the menu bar.

## Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Usage](#usage)
- [Configuration](#configuration)
- [Development](#development)
- [Verification](#verification)
- [License](#license)

## Overview

SayBar is an Xcode-built macOS app skeleton. The current repository contains the app target, placeholder menu bar and settings windows, a small SwiftData model, and test targets. The intended direction is a local-first menu bar controller that can launch, monitor, and configure sibling libraries from [`../SpeakSwiftlyServer`](../SpeakSwiftlyServer) and [`../SpeakSwiftlyMCP`](../SpeakSwiftlyMCP).

### Motivation

The goal is to give Gale a stable macOS menu bar surface for speech tooling that should feel native, lightweight, and always nearby. Instead of treating speech hosting and MCP control as separate terminal-driven workflows, SayBar is meant to become the app-level home for service lifecycle, status visibility, voice profile management, and operator-facing controls.

## Setup

This project is currently set up as an Xcode macOS app, not as a standalone Swift package.

1. Open the project in Xcode:

```sh
open SayBar.xcodeproj
```

2. Select the `SayBar` scheme.
3. Build and run the app on macOS.

The sibling repositories for the planned integrations currently live at:

- [`../SpeakSwiftlyServer`](../SpeakSwiftlyServer)
- [`../SpeakSwiftlyMCP`](../SpeakSwiftlyMCP)

They are not wired into this app yet, so no extra local package setup is required today.

## Usage

Right now, running the app gives you the Xcode-template `MenuBarExtra` shell:

- a menu bar item with placeholder label and system image strings
- a placeholder menu bar window
- a placeholder settings window

There is not yet a service host, status UI, server lifecycle control, or MCP management surface in the app.

The near-term target experience is:

- a basic but recognizable placeholder menu bar UI instead of template text
- app builds and runs cleanly from Xcode
- playback controls for starting and stopping local speech playback flows
- visible server status for the hosted SpeakSwiftly server and MCP surfaces
- visible queue status so pending work is obvious without opening a terminal
- a Settings scene for deeper app and speech configuration

## Configuration

SayBar does not have a dedicated runtime configuration surface yet.

The current app target includes:

- a SwiftData model container for `VoiceProfile`
- a macOS app bundle identifier of `com.galewilliams.SayBar`
- an `mlx-audio-swift` package dependency already present in the Xcode project

When the SpeakSwiftly integrations are added, this section should document how local package references, service paths, model assets, and app preferences are configured.

## Development

This repository is best treated as a native macOS app project first.

- Keep menu bar behavior, settings presentation, and service lifecycle logic simple and direct.
- Prefer documented Xcode and Apple-platform workflows over handwritten project-file edits.
- Keep operator-facing UI and logs explicit enough that service state is obvious at a glance.
- Treat `../SpeakSwiftlyServer` and `../SpeakSwiftlyMCP` as the intended integration boundaries rather than recreating their responsibilities inside SayBar.

Planned implementation slices:

- replace template UI with a stable placeholder menu bar window and a real Settings scene
- wire local package integration for `../SpeakSwiftlyServer` and `../SpeakSwiftlyMCP`
- add app-level build and launch verification for the `SayBar` scheme
- expose playback controls, service lifecycle controls, server status, and queue visibility in the menu bar UI
- grow `VoiceProfile` and app preferences only as real app flows require them

Current project structure:

- `SayBar/` contains the app entrypoint, views, assets, and data models.
- `SayBarTests/` contains unit-test scaffolding.
- `SayBarUITests/` contains UI-test scaffolding.

## Verification

Until more functionality lands, the practical verification loop is:

1. Open `SayBar.xcodeproj` in Xcode.
2. Build and run the `SayBar` scheme.
3. Confirm the app launches and inserts a menu bar item.
4. Open the menu bar window and Settings window and confirm both still render placeholder content.

As the app grows, this section should expand to cover service hosting checks, local package integration checks, and UI verification for menu bar workflows.

Target verification milestones for the next pass are:

1. The app builds successfully in Xcode without template-placeholder breakage.
2. The app launches and shows a non-template menu bar UI.
3. The Settings scene opens and renders app-shaped placeholder configuration.
4. Playback controls render and their action plumbing is visible, even before full backend behavior lands.
5. Server status and queue status surfaces render clearly enough for iterative backend hookup.

## License

This project is licensed under the Apache License, Version 2.0.

- License text: [LICENSE](LICENSE)
- Attribution notice: [NOTICE](NOTICE)
