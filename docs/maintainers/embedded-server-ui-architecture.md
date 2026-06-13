# Embedded Server UI Architecture

## Current Product Boundary

SayBar is a native macOS menu bar app that owns one embedded `SpeakSwiftlyServer` runtime through the public `EmbeddedServer` library surface.

The current boundary is intentionally direct:

- `SayBarApp` stores one `EmbeddedServer` in SwiftUI `@State`
- the menu bar scene reads and controls that `EmbeddedServer` directly
- the settings scene reads that same `EmbeddedServer` directly
- SayBar does not add a second controller or session wrapper on top of the package's app-facing observable model

## Why This Shape

`SpeakSwiftlyServer` 11.0.0 provides the app-facing `@Observable` object that a host app is supposed to own. That surface includes:

- lifecycle entrypoints such as `liftoff()` and `land()`
- observable snapshots for overview, queues, playback, playback events, runtime configuration, backend transitions, current generation jobs, transports, network audio receivers, and recent errors
- direct embedded-host control actions such as voice-profile refresh, default voice selection, backend switching, model reload and unload, and playback controls

Because the package already owns those responsibilities, SayBar should stay focused on:

- compact menu bar presentation
- settings diagnostics
- app wording and app-specific control arrangement
- native macOS affordances like settings presentation and clipboard access

SayBar is intentionally not adopting the standalone-install helper surface in this embedded-runtime-first pass. In `SpeakSwiftlyServer` 11.0.0, that helper surface remains outside the embedded library contract SayBar imports. The current product baseline is still the embedded runtime that lives inside the app process.

`SpeakSwiftlyServer` 11.0.0 also carries remote-generation status on `HostStateSnapshot`, but the public `EmbeddedServer` observable does not publish that snapshot. SayBar stays on direct `EmbeddedServer` ownership and does not add a separate HTTP, MCP, or host-state side channel just to read remote-generation diagnostics.

See [embedded-session-api-coverage.md](embedded-session-api-coverage.md) for the complete matrix of available embedded session API surfaces, current SayBar implementation coverage, and future-scope gaps.

## Lifecycle Ownership

Apple's SwiftUI app model makes the `App` conformer the app entry point and composes app UI from scenes. `SpeakSwiftlyServer` documents `EmbeddedServer` as the one long-lived app-owned object for the embedded runtime, and SayBar keeps that model in SwiftUI `@State` at the `App` boundary.

SayBar follows that model directly:

- `SayBarApp` creates one `EmbeddedServer`
- app launch calls `liftoff()` unless UI tests or operator launch arguments have skipped embedded runtime startup for that launch
- app termination requests `land()` before allowing macOS termination to finish

That keeps ownership flat and keeps runtime startup and cleanup attached to the same app-owned model instead of splitting lifecycle work between multiple wrappers.

## UI Ownership

The current menu bar window is composed from small SwiftUI component views:

- `MenuHeaderComponent`
- `QueueCountComponent`
- `MenuControlGroupComponent`
- `MenuPickerComponent`
- `HorizontalSwipeGestureMonitor`

`MenuBarExtraWindow` owns local UI state for:

- local action feedback text
- local button-busy flags for asynchronous actions
- selected menu surface
- the current slide transition edge

That local state is deliberately UI-local. It is not a second source of truth for runtime state. Picker selections, queue counts, request rows, status text, playback state, active backend, default voice profile, transport rows, network audio rows, and recent-error diagnostics are all read directly from the observable `EmbeddedServer` surface at render time.

The current compact menu layout is split into three horizontal surfaces:

- primary: status plus the power, playback or clipboard speech, and settings controls
- queues: generation and playback queue counts plus active and queued request rows
- quick config: voice profile and speech backend pickers

The menu surface switcher is a local AppKit-backed gesture monitor. It listens for horizontal scroll-wheel gestures while the pointer is inside the menu window and updates only the selected SwiftUI surface. It does not own runtime state or route server actions.

Settings keeps the deeper diagnostics out of the menu bar. The primary Settings tab shows app and high-level runtime state; the diagnostics tab renders runtime details, playback details, configuration details, queue request rows, active generation jobs, transport rows, network audio receiver state, and recent errors. `SettingsDisplayState` is only a display mapping from `EmbeddedServer` snapshots into row values; it is not a second server-state model.

## Clipboard Speech

The clipboard-to-speech button now calls `EmbeddedServer.queueLiveSpeech(...)` directly.

That keeps the app on one package-owned control path instead of mixing direct embedded actions for some controls with localhost HTTP for others.
