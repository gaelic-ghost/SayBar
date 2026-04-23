# Embedded Server UI Architecture

## Current Product Boundary

SayBar is a native macOS menu bar app that owns one embedded `SpeakSwiftlyServer` runtime through the public `EmbeddedServer` library surface.

The current boundary is intentionally direct:

- `SayBarApp` stores one `EmbeddedServer` in SwiftUI `@State`
- the menu bar scene reads and controls that `EmbeddedServer` directly
- the settings scene reads that same `EmbeddedServer` directly
- SayBar does not add a second controller or session wrapper on top of the package's app-facing observable model

## Why This Shape

`SpeakSwiftlyServer` now already provides the app-facing `@Observable` object that a host app is supposed to own. That surface includes:

- lifecycle entrypoints such as `liftoff()` and `land()`
- observable snapshots for overview, queues, playback, runtime configuration, transports, and recent errors
- direct embedded-host control actions such as voice-profile refresh, default voice selection, backend switching, model reload and unload, and playback controls
- newer standalone-install helpers such as `ServerInstallLayout` and retained-log snapshots for a future app-managed standalone mode

Because the package already owns those responsibilities, SayBar should stay focused on:

- compact menu bar presentation
- settings diagnostics
- app wording and app-specific control arrangement
- native macOS affordances like settings presentation and clipboard access

SayBar is intentionally not adopting the standalone-install helper surface yet. That part of the package is useful future app-facing API, but the current product baseline is still the embedded runtime that lives inside the app process.

## Lifecycle Ownership

Apple's Observation guidance for `@Observable` reference models is to keep app-owned model instances in SwiftUI `@State`, and `SpeakSwiftlyServer` now documents the embedded app contract the same way.

SayBar follows that model directly:

- `SayBarApp` creates one `EmbeddedServer`
- app launch calls `liftoff()` unless UI tests or operator launch arguments explicitly disable autostart
- app termination requests `land()` before allowing macOS termination to finish

That keeps ownership flat and keeps runtime startup and cleanup attached to the same app-owned model instead of splitting lifecycle work between multiple wrappers.

## UI Ownership

The current menu bar window is composed from small SwiftUI component views:

- `MenuHeaderComponent`
- `QueueCountComponent`
- `MenuControlGroupComponent`
- `MenuPickerComponent`

`MenuBarExtraWindow` owns local UI state for:

- local action feedback text
- local button-busy flags for asynchronous actions

That local state is deliberately UI-local. It is not a second source of truth for runtime state. Picker selections, queue counts, status text, playback state, active backend, and default voice profile are all read directly from the observable `EmbeddedServer` surface at render time.

The current compact menu layout is:

- header at the top
- queue indicator in the middle
- one button control row for power, playback or clipboard speech, and settings
- one picker row for voice profile and speech backend

## Clipboard Speech

The clipboard-to-speech button now calls `EmbeddedServer.queueLiveSpeech(...)` directly.

That keeps the app on one package-owned control path instead of mixing direct embedded actions for some controls with localhost HTTP for others.
