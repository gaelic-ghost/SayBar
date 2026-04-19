# Embedded Server UI Architecture

## Current Product Boundary

SayBar is a native macOS menu bar app that owns one embedded `SpeakSwiftlyServer` runtime through the public `EmbeddedServer` library surface.

The current boundary is intentionally direct:

- `SayBarApp` creates one `EmbeddedServer`
- the menu bar scene reads and controls that `EmbeddedServer` directly
- the settings scene reads that same `EmbeddedServer` directly
- SayBar does not add a second controller or session wrapper on top of the package's app-facing observable model

## Why This Shape

`SpeakSwiftlyServer` now already provides the app-facing `@Observable` object that a host app is supposed to own. That surface includes:

- lifecycle entrypoints such as `liftoff()` and `land()`
- observable snapshots for overview, queues, playback, runtime configuration, transports, and recent errors
- direct embedded-host control actions such as voice-profile refresh, default voice selection, backend switching, model reload and unload, and playback controls

Because the package already owns those responsibilities, SayBar should stay focused on:

- compact menu bar presentation
- settings diagnostics
- app wording and app-specific control arrangement
- native macOS affordances like settings presentation and clipboard access

## UI Ownership

The current menu bar window is composed from small SwiftUI component views:

- `MenuHeaderComponent`
- `QueueCountComponent`
- `MenuControlGroupComponent`

`MenuBarExtraWindow` owns local UI state for:

- local action feedback text
- local button-busy flags for asynchronous actions

That local state is deliberately UI-local. It is not a second source of truth for runtime state. Picker selections, queue counts, status text, playback state, active backend, and default voice profile are all read directly from the observable `EmbeddedServer` surface at render time.

## Clipboard Speech

The clipboard-to-speech button now calls `EmbeddedServer.queueLiveSpeech(...)` directly.

That keeps the app on one package-owned control path instead of mixing direct embedded actions for some controls with localhost HTTP for others.
