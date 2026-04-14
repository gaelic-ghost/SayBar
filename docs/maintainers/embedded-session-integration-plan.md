# SayBar Embedded Session Integration Plan

## Purpose

This document now serves as the current architecture record for SayBar's embedded-session-first implementation. SayBar currently hosts `SpeakSwiftlyServer` through the server package's embedded-session API instead of supervising a separate LaunchAgent-managed server process.

The active architecture decision that keeps this embedded-session model as the product baseline is recorded in [adr-0001-keep-embedded-session-architecture.md](adr-0001-keep-embedded-session-architecture.md).

This remains the preferred implemented path because it keeps the ownership boundaries honest:

- SayBar owns the macOS app lifecycle, menu bar UI, settings UI, and app-facing supervision surface.
- `SpeakSwiftlyServer` owns transport hosting, runtime orchestration, typed state snapshots, playback control, and server-facing configuration behavior.
- `SpeakSwiftly` continues to own the underlying speech runtime, worker lifecycle, and profile behavior.

If future product requirements change and the service must outlive the app UI process, revisit the LaunchAgent-backed install contract. That is a real architectural pivot, not a small follow-up tweak.

## Status

The embedded-session architecture described here is already implemented in the standalone `SayBar` repository.

Implemented surfaces in the app repo include:

- one app-owned `SpeakSwiftlyController`
- one embedded `SpeakSwiftlyServer` session started through `EmbeddedServerSession`
- menu bar status and quick-action controls
- Settings sections for runtime, playback, transports, and diagnostics
- app-owned status presentation tests

Open work that still sits outside this document's completed embedded-session pass includes:

- explicit launch, relaunch, and quit behavior verification
- any future decision to pivot toward an external controller or launch-agent-backed service ownership

## Documented Platform And Package Constraints

### SwiftUI scene behavior

This implementation depends on the documented SwiftUI scene model:

- `MenuBarExtra` is the SwiftUI scene for functionality that should remain available from the system menu bar even when the app is inactive.
- `MenuBarExtra(...).menuBarExtraStyle(.window)` is the documented path for a richer, popover-like window surface instead of a plain pull-down menu.
- `Settings` is the documented SwiftUI scene for macOS app settings and enables the app's standard Settings menu item automatically.

That scene split maps to SayBar's current product shape:

- the menu bar window shows immediate status and common actions
- the Settings scene holds deeper configuration, diagnostics, and explanatory surfaces

Current accessibility and UI-automation findings for the menu bar surface are maintained separately in [accessibility-and-ui-automation-notes.md](accessibility-and-ui-automation-notes.md) so the implementation record here stays focused on product architecture and ownership boundaries.

### Server package behavior

This implementation depends on the public `SpeakSwiftlyServer` embedding surface already described in the server repository:

- `EmbeddedServerSession.start(...)` starts an in-process shared server session using the same config-loading path as the standalone server.
- `EmbeddedServerSession.state` exposes the app-facing `@Observable` `ServerState`.
- `ServerState` carries host overview, queue snapshots, playback state, recent errors, runtime configuration, and transport snapshots.
- `ServerState` exposes app-facing actions for:
  - pausing and resuming playback
  - clearing the playback queue
  - cancelling one playback request
  - refreshing voice-profile-related state as exposed by the server package

The app consumes those public surfaces directly instead of re-deriving equivalent state through HTTP polling or by reaching into server internals.

## Architectural Decision

Use one app-owned controller as the single integration seam between SwiftUI and the embedded server session.

This is the current durable building-block change that the repo has already implemented, not a stopgap.

The controller's job is narrow:

- start and stop a single `EmbeddedServerSession`
- expose a compact app-facing status model for menu bar and Settings views
- surface app actions that delegate into `ServerState`
- translate detailed host snapshots into a small operator vocabulary appropriate for the app UI

The controller should not:

- duplicate `ServerState` with a second large mirrored model graph
- recreate HTTP or MCP clients for in-process control
- hide every server value behind wrappers just to look more architectural
- persist server-owned runtime state in SwiftData
- invent new transport abstractions

## Recommended Ownership Model

### SayBar owns

- app launch and shutdown behavior
- menu bar insertion state
- presentation structure for the menu bar and Settings
- app-specific status summarization
- app wording and operator-facing explanations
- app-only preferences such as whether the extra is inserted

### SpeakSwiftlyServer owns

- starting and stopping the embedded server runtime
- host overview and transport state
- playback and generation queue snapshots
- runtime configuration and default voice profile state exposed through the server package
- recent error capture and host-level diagnostics

### Future LaunchAgent path owns

This architecture intentionally does not use the LaunchAgent install path. Keep that path in reserve for a later architectural change where the service must keep running independently of the app.

## Current Implementation Shape

### 1. One real app controller

The repo now uses one concrete, app-owned `@MainActor` controller type:

- `SayBar/Controllers/SpeakSwiftlyController.swift`

That controller owns exactly one optional `EmbeddedServerSession`, derives the app-facing service-state vocabulary, and exposes the app actions used by the menu bar and Settings surfaces.

Current app-facing status vocabulary:

- `stopped`
- `starting`
- `ready`
- `degraded`
- `broken`

The mapping stays local to the controller and is derived from embedded-session state instead of a second mirrored model tier.

### 2. Thin app-facing translation

The current implementation keeps server terminology available for diagnostics, but not as the app's top-level vocabulary.

In practice that means:

- server detail such as `workerStage`, transport state, and startup errors inform the app status
- the menu bar leads with a compact headline and detail string instead of raw host fields
- Settings remains the place for fuller runtime and transport inspection

### 3. Embedded session owned by the app process

The controller is created at the app boundary in:

- `SayBar/SayBarApp.swift`

The app currently starts the embedded session through the controller during app startup unless autostart is disabled by process argument.

The controller remains the only app-repo type that directly touches `EmbeddedServerSession`.

### 3a. Current runtime ownership and actor boundaries

The current ownership model is app-wide and process-local:

- `SayBarApp` owns one `SpeakSwiftlyController`
- `SpeakSwiftlyController` owns one optional `EmbeddedServerSession`
- `EmbeddedServerSession` owns the app-facing `ServerState` and the internal host lifecycle hooks
- `ServerHost` owns the actual runtime, transport publishing, and host-side background tasks

That means the embedded session is:

- app-owned, not view-owned
- shared by the menu bar surface and Settings
- persistent for the lifetime of the app process
- intentionally not persistent beyond app quit

The current actor split is important:

- `SpeakSwiftlyController` is `@MainActor`
- `EmbeddedServerSession` is `@MainActor`
- `ServerState` is `@MainActor`
- `ServerHost` is an actor
- the `SpeakSwiftly` runtime uses its own task-driven preload, queue, and status-event work underneath the host

So the current startup path is not "everything runs on the main thread." The app-facing bootstrap and observable state are main-actor-isolated, but the host and runtime already fan out into concurrent task work after bootstrap.

The current implementation detail that still deserves scrutiny is that the app-facing bootstrap wrapper is more main-actor-shaped than the underlying host likely requires. The most likely future cleanup direction is:

- keep UI-facing observable state and final session attachment on the main actor
- move as much expensive embedded-session bootstrap work off the main actor as the package boundary safely allows
- keep the ownership model the same while reducing how much startup orchestration has to pass through a main-actor wrapper

One current caveat remains: local playback setup is intentionally more main-actor-bound than the rest of runtime startup. `SpeakSwiftly` currently creates its playback controller through a `@MainActor` dependency hook, and `AudioPlaybackDriver` is itself `@MainActor` because it owns `AVAudioEngine`, workspace notifications, and macOS routing-arbitration behavior. That means not all startup work is an accidental main-actor hop.

### 4. Menu bar surface

The menu bar window is implemented in:

- `SayBar/Views/MenuBarExtraWindow.swift`

The current menu bar answers three operator questions quickly:

1. Is the service up?
2. Is it healthy enough to use?
3. What is the next common action?

Current menu bar contents include:

- service symbol, headline, and detail copy
- compact worker and queue summaries
- start or restart
- stop
- playback pause or resume when relevant
- playback queue clearing when relevant
- open Settings

One implementation rule is now important enough to call out explicitly:

- keep `MenuBarExtraWindow` reading app-facing controller snapshots, not nested live `ServerState` graphs through computed optional indirection

The current menu-window freeze investigation showed that the scene stays stable when the view renders flattened controller-owned metrics, and becomes unstable when the view directly traverses `ssController.serverState` into nested `ServerState` properties during scene construction.

### 5. Settings surface

The Settings window is implemented in:

- `SayBar/Views/SettingsWindow.swift`

Current Settings sections include:

- General
- Runtime
- Playback
- Transports
- Diagnostics

This is where the app currently puts the deeper inspection surface that does not belong in the menu bar window.

### 6. Persistence boundary

The current implementation keeps persistence narrow.

App-owned persistence currently uses `@AppStorage` for app-level preferences such as whether the menu bar extra is inserted. The app does not currently use SwiftData or a mirrored local database for server runtime state.

### 7. Operator-facing errors

The controller converts startup and runtime failures into descriptive app-facing messages. The standard remains:

- say what failed
- say where it failed
- include the most likely cause when the controller has one
- point Gale toward the next useful surface or action

## Implementation Status By Area

### Status presentation and tests

The current status-presentation logic is covered by app-owned tests in:

- `SayBarTests/SayBarTests.swift`

Those tests cover the derived presentation for stopped, starting, ready, degraded, and broken cases.

## Remaining work outside this document

This embedded-session architecture record does not settle the longer-term product decision about whether SayBar should later attach to an external service or own a launch-agent-backed helper.

That future decision space is tracked in:

- [controller-architecture-options.md](controller-architecture-options.md)

## Verification Plan

Use serialized Xcode validation only.

Minimum verification for embedded-session app work:

1. build the `SayBar` scheme
2. run the app
3. confirm the menu bar extra opens and reflects real embedded-session state
4. confirm the Settings scene opens and shows deeper runtime detail
5. verify start, stop, and restart behavior does not create duplicate sessions

Current runtime-architecture and sandbox follow-up checks before the next deeper integration pass:

1. verify the effective signed SayBar app includes both `com.apple.security.network.server` and `com.apple.security.network.client`
2. re-check Xcode runtime logs after the latest `SpeakSwiftlyServer` bootstrap changes land
3. confirm whether the current Security and audio-runtime warnings still reproduce when embedded autostart is enabled
4. isolate which remaining startup work is truly required on the main actor versus only initiated from a main-actor wrapper today
5. keep the app-wide controller ownership model stable unless a broader architecture decision is made explicitly

## Follow-On Documentation Work

If the app remains embedded-first, keep this document updated as the current architecture record.

If the chosen implementation path widens beyond this document's embedded-session model, stop and convert this document into a historical architecture record while moving the new active architecture guidance into a replacement document.
