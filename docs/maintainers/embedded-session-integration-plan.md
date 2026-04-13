# SayBar Embedded Session Integration Plan

## Purpose

This document turns the current SayBar direction into a concrete implementation plan: SayBar should host `SpeakSwiftlyServer` through the server package's embedded-session API instead of supervising a separate LaunchAgent-managed server process.

This is the preferred first integration path because it keeps the app's ownership boundaries honest:

- SayBar owns the macOS app lifecycle, menu bar UI, settings UI, and app-facing supervision surface.
- `SpeakSwiftlyServer` owns transport hosting, runtime orchestration, typed state snapshots, playback control, and server-facing configuration behavior.
- `SpeakSwiftly` continues to own the underlying speech runtime, worker lifecycle, and profile behavior.

If future product requirements change and the service must outlive the app UI process, revisit the LaunchAgent-backed install contract. That is a real architectural pivot, not a small follow-up tweak.

## Documented Platform And Package Constraints

### SwiftUI scene behavior

This plan depends on the documented SwiftUI scene model:

- `MenuBarExtra` is the SwiftUI scene for functionality that should remain available from the system menu bar even when the app is inactive.
- `MenuBarExtra(...).menuBarExtraStyle(.window)` is the documented path for a richer, popover-like window surface instead of a plain pull-down menu.
- `Settings` is the documented SwiftUI scene for macOS app settings and enables the app's standard Settings menu item automatically.

That scene split maps well to SayBar's intended product shape:

- the menu bar window should show immediate status and common actions
- the Settings scene should hold deeper configuration, diagnostics, and explanatory surfaces

### Server package behavior

This plan depends on the public `SpeakSwiftlyServer` embedding surface already described in the server repository:

- `EmbeddedServerSession.start(...)` starts an in-process shared server session using the same config-loading path as the standalone server.
- `EmbeddedServerSession.state` exposes the app-facing `@Observable` `ServerState`.
- `ServerState` already carries host overview, queue snapshots, playback state, recent errors, runtime configuration, transport snapshots, and voice profile actions.
- `ServerState` already exposes app-facing actions for:
  - refreshing voice profiles
  - setting and clearing the default voice profile
  - pausing and resuming playback
  - clearing the playback queue
  - cancelling one playback request

The app should consume those public surfaces directly instead of re-deriving equivalent state through HTTP polling or by reaching into server internals.

## Architectural Decision

Use one app-owned controller as the single integration seam between SwiftUI and the embedded server session.

This is a durable building-block change, not a stopgap.

The controller's job is narrow:

- start and stop a single `EmbeddedServerSession`
- expose a compact app-facing status model for menu bar and settings views
- surface a few app-owned actions that delegate into `ServerState`
- translate detailed host snapshots into a small operator vocabulary appropriate for the app UI

The controller should not:

- duplicate `ServerState` with a second large mirrored model graph
- recreate HTTP or MCP clients for in-process control
- hide every server value behind wrappers just to look more "architectural"
- persist server-owned runtime state in SwiftData
- invent new transport abstractions

## Recommended Ownership Model

### SayBar owns

- app launch and shutdown behavior
- menu bar insertion state
- presentation structure for the menu bar and Settings
- app-specific status summarization
- app wording and operator-facing explanations
- any app-only preferences such as whether the extra is inserted or which sections are expanded in the UI

### SpeakSwiftlyServer owns

- starting and stopping the embedded server runtime
- host overview and transport state
- playback and generation queue snapshots
- runtime configuration and default voice profile state
- voice profile list refresh and mutation actions
- recent error capture and host-level diagnostics

### Future LaunchAgent path owns

This plan intentionally does not use the LaunchAgent install path for first integration. Keep that path in reserve for a later architectural change where the service must keep running independently of the app.

## Implementation Shape

## 1. Introduce one real app controller

Replace the current empty `SpeakSwiftlyController` scaffold with one app-owned controller type.

Recommended shape:

- keep it `@MainActor`
- keep it concrete, not protocol-first
- let it own exactly one optional `EmbeddedServerSession`
- expose a compact derived app status enum
- expose a handful of app actions that directly call through to the embedded session or `ServerState`

Suggested responsibilities:

- `startIfNeeded()`
- `stopIfRunning()`
- `restart()`
- `refreshVoiceProfiles()`
- `pausePlayback()`
- `resumePlayback()`
- `clearPlaybackQueue()`
- `cancelPlaybackRequest(_:)`

Suggested derived app-facing state:

- `serviceState: SayBarServiceState`
- `statusHeadline: String`
- `statusDetail: String`
- `isBusy: Bool`
- `canStart`
- `canStop`
- `canPausePlayback`
- `canResumePlayback`

Suggested app-facing status enum:

- `stopped`
- `starting`
- `ready`
- `degraded`
- `broken`

The mapping should be thin and explicit. Derive it primarily from `ServerState.overview`, `runtimeRefresh`, `transports`, and `recentErrors`.

## 2. Keep translation thin and local

Do not expose raw server terminology directly as the top-level app state.

Examples:

- server detail like `workerStage`, `serverMode`, or transport-specific state should inform app status, not become the app's primary vocabulary
- queue counts and active request data should remain available for diagnostics, but the menu bar's first job is to answer "is the service usable right now?"

The translation should happen in one place inside the controller through a small set of computed properties or helper methods.

Avoid creating a dedicated mapper type unless the logic becomes meaningfully complex.

## 3. Start the embedded session from the app process

Treat the embedded session as app-owned runtime, not as an automatically booted dependency hidden elsewhere.

Recommended startup behavior for the first pass:

- create the controller at the app boundary
- start the embedded session once from the app's SwiftUI lifecycle
- keep the session alive for the lifetime of the app process
- stop it cleanly on app termination if needed

Recommended scene-level ownership:

- instantiate the controller once in `SayBarApp`
- inject it into the menu bar and settings views

The controller should be the only type in this repo that directly touches `EmbeddedServerSession`.

## 4. Build the menu bar around quick status and common actions

The menu bar window should answer three questions quickly:

1. Is the service up?
2. Is it healthy enough to use?
3. What is the next common operator action?

First-pass menu bar contents:

- service state chip or row
- short human-readable headline
- short diagnostic detail if degraded or broken
- buttons for:
  - start or restart
  - stop
  - open Settings
- compact playback controls when playback is active or paused

The menu bar should not become a dump of every queue and runtime field. Keep it fast to scan.

## 5. Use Settings for deep inspection and low-frequency controls

Settings should own the surfaces that are too detailed or too infrequent for the menu bar:

- runtime detail
- transport detail
- recent errors
- voice profile list and default voice profile selection
- queue inspection
- future app-owned configuration

Recommended first-pass sections:

- General
  - whether the menu bar extra is inserted
  - any app-owned behavior toggles
- Runtime
  - worker mode, worker stage, readiness, default voice profile
- Playback
  - current playback state, active request, queue counts
- Voice Profiles
  - current list
  - refresh action
  - current default profile
- Diagnostics
  - startup error
  - recent errors
  - transport snapshots

## 6. Keep persistence narrow

Do not use SwiftData for the server session or for mirrored runtime state in the first pass.

Prefer simple app-local persistence only for app-owned preferences, such as:

- whether the menu bar extra is inserted
- perhaps simple UI presentation state if it is worth remembering

Use `@AppStorage` first for those app-owned values.

Only introduce SwiftData if a later requirement clearly needs app-local structured records that are not already owned by the embedded server.

## 7. Make errors operator-friendly at the app boundary

The app should preserve the repo-wide guidance that every operator-facing message is specific and readable.

That means the controller should convert raw host failures into messages that tell Gale:

- what failed
- where it failed
- what the most likely cause is
- what action is available next

Examples of the kind of wording to prefer:

- "SayBar could not start the embedded SpeakSwiftlyServer session. Likely cause: the server package threw an initialization error before the runtime reached a ready state."
- "SpeakSwiftlyServer is running, but the worker runtime is not ready yet. Likely cause: model loading or backend startup is still in progress."
- "The embedded server reported a degraded state after startup. Check Runtime and Diagnostics in Settings for the latest transport and worker details."

## Phase Plan

## Phase 1: Replace scaffolds with app-owned structure

Goal:

- remove placeholder menu bar and settings content
- create the first real app-owned controller
- wire the controller into the app scene tree

Deliverables:

- `SayBarApp` owns one controller instance
- menu bar and settings views receive controller access
- placeholder `Hello, World!` content is gone
- menu bar shows initial service state

Verification:

- app builds and launches
- menu bar extra opens
- settings window opens
- no duplicate embedded sessions are started

## Phase 2: Start and observe the embedded server session

Goal:

- start the embedded session in the app process
- surface real host and runtime state in the UI

Deliverables:

- controller can start one `EmbeddedServerSession`
- app status enum is derived from live `ServerState`
- menu bar shows `starting`, `ready`, `degraded`, or `broken` based on real host state
- settings show runtime and diagnostics data

Verification:

- app reaches a stable ready state when the embedded session succeeds
- startup failures are visible in the UI with useful wording
- stopping and restarting do not leak multiple sessions

## Phase 3: Add core operator actions

Goal:

- make the app useful as a supervision surface instead of just a monitor

Deliverables:

- playback pause and resume actions
- clear playback queue
- cancel request action where relevant
- refresh voice profiles
- default voice profile selection or reset

Verification:

- actions mutate the live embedded state
- action availability follows actual state
- failure messages remain human-readable

## Phase 4: Refine app-owned UX and diagnostics

Goal:

- make the app easy to scan and trustworthy during failures

Deliverables:

- compact menu bar summary UI
- clearer settings sections
- recent error presentation
- diagnostics copy that explains likely causes

Verification:

- degraded and broken states are visually distinct
- Gale can tell what is wrong without reading raw implementation terms first

## Open Questions To Resolve During Implementation

- What is the correct app-owned rule for when SayBar should automatically start the embedded session?
  - always on app launch
  - only after the menu bar extra appears
  - user-controlled from settings

- Should "stop" fully tear down the embedded session, or should the first pass support only start and restart while keeping the app itself alive?

- Which `ServerState` fields should appear directly in the menu bar window, and which should stay settings-only?

- Does the currently pinned `SpeakSwiftlyServer` package version in SayBar expose every embedded-session API the app needs, or do we need a deliberate package bump before implementation begins?

## Explicit Non-Goals For The First Pass

- no LaunchAgent-based service installation
- no background helper that survives the app process
- no HTTP polling path for in-process control
- no MCP client layer inside SayBar
- no SwiftData mirror of server runtime state
- no new abstraction tier unless the real ownership boundary changes

## Suggested Initial File Touches

Assuming the first implementation pass follows this plan, these are the likely first files to change:

- `SayBar/SayBarApp.swift`
- `SayBar/Controllers/SpeakSwiftlyController.swift`
- `SayBar/Views/MenuBarExtraWindow.swift`
- `SayBar/Views/SettingsWindow.swift`

Additional small app-local model files are acceptable if they carry truly app-owned concepts like the compact `SayBarServiceState` enum, but avoid spreading the first pass across many files without a concrete benefit.

## Verification Plan

Use serialized Xcode validation only.

Minimum verification for the first implementation pass:

1. build the `SayBar` scheme
2. run the app
3. confirm the menu bar extra opens and reflects real embedded-session state
4. confirm the Settings scene opens and shows deeper runtime detail
5. verify start, stop, and restart behavior does not create duplicate sessions

If unit tests are added around the status mapping logic, keep them narrow and app-owned.

## Follow-On Documentation Work

When implementation begins, update these repo-facing docs in the same pass:

- `README.md`
- `ROADMAP.md`
- this maintainer plan if the architecture changes materially

If the chosen implementation path widens beyond this document's embedded-session model, stop and get an explicit decision before leaving a hybrid architecture behind.
