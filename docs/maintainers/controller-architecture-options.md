# SayBar Controller Architecture Options

## Purpose

This document captures the main architectural options for moving SayBar from its current embedded-session model toward a more optional macOS controller that can attach to a separately running `SpeakSwiftlyServer`.

The current repo decision is to keep the embedded-session architecture as the product baseline. See [adr-0001-keep-embedded-session-architecture.md](adr-0001-keep-embedded-session-architecture.md).

This is a future-direction decision memo, not the current architecture source of truth for the repo. The current implemented architecture is the embedded-session-first model described in [embedded-session-integration-plan.md](embedded-session-integration-plan.md).

The goal is to make the decision space explicit before code changes widen scope. The important split is:

- process ownership: who installs, starts, stops, and keeps the server alive
- control transport: how SayBar observes and controls the server once it exists

Right now those are fused together because SayBar only knows the embedded, in-process session path. A controller-oriented future should separate them on purpose instead of accreting ad hoc exceptions.

## Current State

Today SayBar uses the embedded-server package surface directly:

- `SayBar` creates one `SpeakSwiftlyController`
- the controller starts one `EmbeddedServerSession`
- the embedded session starts the shared `SpeakSwiftlyServer` runtime inside the app process
- the menu bar and Settings views read the package's app-facing `ServerState`
- operator actions delegate directly into the embedded session or `ServerState`

That is the current source of truth in the app repo because it is the path actually implemented and tested.

Relevant app-repo and sibling-repo surfaces:

- `SayBar/Controllers/SpeakSwiftlyController.swift`
- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/EmbeddedServerSession.swift`
- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/Host/ServerState.swift`

This document assumes that embedded-session-first implementation as the baseline and explores what would need to change only if the product deliberately pivots away from it.

## Documented Platform Constraints

### Apple Service Management guidance

The controller options here depend on documented macOS behavior, not memory or convention.

Apple's current guidance for macOS 13 and later is:

- `SMAppService` is the supported API for login items, launch agents, and launch daemons that belong to an app bundle.
- `SMAppService.agent(plistName:)` is the supported API for a bundled launch agent.
- `register()` and `unregister()` replace the older pattern of writing plists directly into `~/Library/LaunchAgents` or `/Library/LaunchAgents`.
- bundled launch agents belong in the app bundle under `Contents/Library/LaunchAgents`.
- when migrating older helper-executable setups, Apple calls the direct plist-install path a legacy model and documents `AssociatedBundleIdentifiers` and legacy-status APIs for compatibility.

Authoritative references:

- [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [SMAppService.register()](https://developer.apple.com/documentation/servicemanagement/smappservice/register())
- [Updating helper executables from earlier versions of macOS](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- [Updating your app package installer to use the new Service Management API](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api)

### What this means for SayBar

There are two valid families of launch-agent integration, and they should not be blurred together:

- bundled app-owned helper model via `SMAppService`
- legacy externally installed plist model managed through `launchctl`

If SayBar adopts the bundled `SMAppService` path, that is a real packaging and signing change. It is not just a nicer wrapper around the current direct-install launch-agent world.

If SayBar remains a controller for an externally installed service, that remains a legacy-style launch-agent arrangement even if the UI becomes polished.

## Existing Server-Side Surfaces

Before inventing any new manager layer, it is important to note what `SpeakSwiftlyServer` already exposes.

### Native launch-agent support already exists

`SpeakSwiftlyServerTool` already contains native launch-agent commands:

- `launch-agent print-plist`
- `launch-agent install`
- `launch-agent uninstall`
- `launch-agent status`

Relevant local surfaces:

- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/LaunchAgent/LaunchAgentCommands.swift`
- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/LaunchAgent/LaunchAgentOptions.swift`
- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/LaunchAgent/LaunchAgentRuntime.swift`

That means SayBar does not need to be the first place that learns how to write plists, boot services out, retry bootstrap races, or interpret `launchctl` failure details.

### App-managed install layout already exists

`SpeakSwiftlyServer` already defines a path contract for a per-user installed service:

- launch-agent plist location
- Application Support paths
- cache paths
- runtime profile-root paths
- stdout and stderr log paths

Relevant local surface:

- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/AppManagedInstallLayout.swift`

That is a strong signal that SayBar should either use this contract directly or intentionally replace it with a new bundled-helper contract, not guess at its own filesystem layout.

### Remote control and state surfaces already exist

The external server already exposes enough HTTP surface for SayBar to attach as a controller:

- `GET /readyz`
- `GET /runtime/host`
- `GET /runtime/status`
- `GET /runtime/configuration`
- `PUT /runtime/configuration`
- `POST /runtime/backend`
- `POST /runtime/models/reload`
- `POST /runtime/models/unload`
- `GET /playback/state`
- `GET /playback/queue`
- `POST /playback/pause`
- `POST /playback/resume`
- `DELETE /playback/queue`
- `DELETE /playback/requests/:request_id`

Relevant local surfaces:

- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/HTTP/HTTPRuntimeRoutes.swift`
- `../speak-to-user/monorepo/packages/SpeakSwiftlyServer/Sources/SpeakSwiftlyServer/HTTP/HTTPPlaybackRoutes.swift`

This means a controller-oriented SayBar can use HTTP first and does not need to become an MCP client just to drive local operator controls.

## Design Goals For A Controller-Oriented SayBar

If SayBar becomes more of an optional controller, the architecture should preserve these goals:

- SayBar should be able to observe a running server without necessarily owning its process lifetime.
- SayBar should be able to explain whether it is embedding, attaching, or supervising a launch-agent-managed service.
- operator actions should stay readable and honest about what they actually do.
- SayBar should not become the place where launchd semantics, server config semantics, and runtime internals all get duplicated.
- the UI should be able to project one compact state model regardless of which control mode is active.

## Option 1: Full App-Owned Bundled Launch Agent via `SMAppService`

### Summary

SayBar ships `SpeakSwiftlyServer` as an app-bundled helper executable plus bundled launch-agent plist, registers that helper with `SMAppService.agent(plistName:)`, and then attaches to the live helper over HTTP or another explicit control transport.

### What this unlocks

- an Apple-native app-owned helper model
- Login Items integration that is attributed to SayBar directly through the supported bundled-helper path
- a polished "SayBar installs and owns the background service" story
- less reliance on ad hoc repo-root shell scripts once the helper is packaged properly

### What this removes

- the mismatch between "this is a Mac app" and "the actual service install story still lives in external scripts"
- direct writes to `~/Library/LaunchAgents` from repo scripts as the main install path

### Required changes

- build and stage `SpeakSwiftlyServerTool` or an equivalent helper executable as a bundled helper product
- install a bundled launch-agent plist into `Contents/Library/LaunchAgents`
- change packaging, signing, and bundle layout to satisfy Apple's `SMAppService` expectations
- teach SayBar to call `SMAppService.agent(plistName:)`, `register()`, `unregister()`, and inspect service status
- add a remote-session client in SayBar so the app attaches to the helper instead of embedding the runtime
- define how bundled helper config, writable data, logs, and runtime state move from the bundle into writable user locations

### Risks

- this is the largest packaging pivot
- helper signing and bundle layout need to be correct, or the app will have a confusing half-installed state
- the current `SpeakSwiftlyServer` install-layout contract would need to be reconciled with the bundled-helper contract instead of casually reused

### Architectural classification

This is a durable building-block change. It is the most Apple-native finished model, but it is not the cheapest first migration.

## Option 2: SayBar Delegates Launch-Agent Ownership To `SpeakSwiftlyServer`, Then Attaches

### Summary

SayBar remains the UI controller, but the server package remains the source of truth for launch-agent installation and status. SayBar asks `SpeakSwiftlyServerTool` to install, uninstall, or inspect the external launch agent, then attaches to the running service over HTTP.

### What this unlocks

- a controller-oriented app without immediately solving bundled-helper packaging
- one clear owner for launch-agent semantics: the server project
- reuse of the existing install layout, `launchctl` retry logic, and status reporting
- a practical path where SayBar can manage or repair a background service while staying honest about process ownership

### What this removes

- the need for SayBar to learn or duplicate launchd mechanics
- the current coupling between SayBar and the embedded-only session path

### Required changes

- add a remote-session client in SayBar that can project app-facing state from the external server's HTTP surface
- refactor `SpeakSwiftlyController` so it can drive one of multiple backend modes instead of assuming `EmbeddedServerSession`
- decide whether SayBar links launch-agent code from `SpeakSwiftlyServer` directly or shells out to `SpeakSwiftlyServerTool`
- add explicit UI wording for ownership mode, for example:
  - embedded in SayBar
  - attached to external server
  - managing launch-agent-backed server
- decide whether install and uninstall actions are available in the menu bar, Settings, or both

### Recommended approach inside this option

Prefer HTTP for the control transport first.

The package already exposes enough HTTP surface for:

- readiness probing
- runtime-state inspection
- playback controls
- queue controls
- runtime backend and model operations

That means SayBar can implement an attached session client without needing to become an MCP client or without reproducing host internals in the UI layer.

### Risks

- the external install story still remains a legacy-style launch-agent model rather than the newer bundled `SMAppService` model
- the app needs careful wording so Gale always knows whether SayBar is controlling a service it owns or one installed elsewhere

### Architectural classification

This is the recommended durable first migration. It is the best balance between practical reuse and honest ownership boundaries.

## Option 3: Pure Attachment Model With No Install Ownership

### Summary

SayBar does not install or uninstall anything. It only discovers or reads a configured host and port, probes the server, and exposes operator controls against that running service.

### What this unlocks

- the safest optional-controller story
- minimal responsibility for SayBar
- no app-owned install or packaging complexity

### What this removes

- any expectation that SayBar is responsible for launch-agent installation, repair, or teardown

### Required changes

- add a remote-session client
- add connection settings or a discovery story for host and port
- decide what the app says when no server is reachable
- move install, repair, and service-lifecycle instructions into docs or out-of-app tooling

### Risks

- this can feel incomplete from a product perspective because the app controls only what it can find
- users still need some other path to install and maintain the background server

### Architectural classification

This is a conscious stopgap or a minimalist product choice, depending on intent. It is excellent for non-invasive attachment, but weak as a complete app-owned local-service story.

## Option 4: Hybrid Model With Embedded Fallback And External Attachment

### Summary

SayBar tries to attach to an external server first and falls back to embedding the runtime when no external service is available, or vice versa.

### What this unlocks

- a very flexible local-development story
- a product surface that can work in multiple operator environments

### What this removes

- the assumption that one process-ownership model must fit every scenario

### Required changes

- everything from the remote-session client work
- persistent mode selection and discovery behavior
- very clear UI status about which mode is active
- branching semantics for start, stop, restart, and install actions

### Risks

- the control model gets muddy quickly
- the same button can mean different things across modes
- lifecycle bugs and wording bugs become more likely because ownership semantics vary per mode

### Architectural classification

This is a broad capability expansion, not the right first simplification pass. It should only happen if SayBar genuinely needs to support both worlds at once.

## Recommended Direction If SayBar Pivots Beyond Embedded Session

### Recommendation

If SayBar deliberately pivots beyond the current embedded-session architecture, take Option 2 first: SayBar becomes a controller that can attach to an external `SpeakSwiftlyServer` and can delegate launch-agent install and status behavior to `SpeakSwiftlyServerTool`.

Do not jump straight from today's embedded model to the full bundled-helper `SMAppService` path unless the product requirement is already clear that SayBar itself must own installation as a polished Mac app.

### Why this is the recommended first move

It gives SayBar the controller behavior you would be exploring in that pivot:

- optional app surface
- attach to an existing running server
- operate against a launch-agent-backed service
- keep service ownership boundaries honest

And it does that without throwing away the launch-agent work already implemented in `SpeakSwiftlyServer`.

This direction also keeps the future path open:

- if it proves sufficient, SayBar stays a controller over a server-owned launch-agent model
- if later product polish demands Apple-native app-owned helper registration, SayBar can still move to Option 1 as a deliberate packaging migration

### Proposed migration phases

#### Phase A: Introduce a backend-mode-aware controller

Refactor SayBar's app-owned controller so it can represent:

- embedded session
- attached remote session
- disconnected state

Do this before adding launch-agent UI. Otherwise the controller remains structurally embedded-only.

#### Phase B: Add a remote-session client

Create a SayBar-side client that:

- probes `/readyz`
- reads the runtime and playback routes
- executes pause, resume, queue-clear, and other operator controls over HTTP
- maps remote snapshots into the same app-facing presentation vocabulary used today

This keeps the menu bar and Settings mostly backend-agnostic.

#### Phase C: Delegate install and status actions to `SpeakSwiftlyServer`

Teach SayBar to surface actions such as:

- install launch-agent-backed server
- uninstall launch-agent-backed server
- inspect launch-agent status
- reconnect to running service

But implement those actions by invoking or linking the server-side launch-agent logic instead of reproducing it in SayBar.

#### Phase D: Decide whether the product needs the bundled-helper `SMAppService` pivot

Only after the controller model is working should SayBar decide whether the external launch-agent arrangement is enough or whether the app should become the true installer and owner through bundled-helper packaging.

That later pivot would be:

- packaging-heavy
- signing-heavy
- release-process-heavy

and should be treated as a separate architecture decision.

### Concrete app changes if Phase A and Phase B start

If SayBar begins the controller migration now, the most likely app-repo work is:

- split the current single embedded-only controller into one app-facing control model plus pluggable backend implementations
- preserve one compact app-facing service-state vocabulary:
  - stopped
  - starting
  - ready
  - degraded
  - broken
- add backend identity to the UI model so operator wording can say whether the service is:
  - embedded inside SayBar
  - attached over HTTP
  - managed through an installed launch agent
- keep menu bar actions focused on operational clarity instead of setup complexity
- move launch-agent install and repair detail into Settings rather than the menu bar window

### Things SayBar should not do during this migration

- Do not let SayBar become a second source of truth for server filesystem layout.
- Do not duplicate launch-agent bootstrap and retry logic if `SpeakSwiftlyServer` already owns it.
- Do not mix bundled `SMAppService` helper assumptions with legacy externally installed plist assumptions in one ambiguous half-step.
- Do not present vague UI that hides whether SayBar is embedding a runtime or controlling some other process.
- Do not widen to embedded plus external plus bundled-helper support all at once unless there is a concrete product requirement for that breadth.

### Open questions

- Should SayBar invoke `SpeakSwiftlyServerTool` as a subprocess, or should it link the server package's launch-agent types directly and call them in-process?
- What is the right user-facing term for the external service mode: `attached`, `connected`, `controller`, or something more explicit like `attached to background server`?
- Should launch-agent installation stay a maintainer or power-user action in Settings, or should it be a first-class onboarding flow?
- Does SayBar need connection discovery, or is one app-owned configured host and port enough for the first attached-session pass?
- If SayBar later adopts `SMAppService`, should the existing app-managed install layout migrate forward, or should the bundled-helper model get its own dedicated install contract?

## Decision Summary

If the product goal becomes "SayBar should behave more like an optional controller that can attach to a running server," the next good architecture is:

- keep SayBar's app-facing state and UI
- add a remote-session backend
- delegate launch-agent install semantics to `SpeakSwiftlyServer`
- postpone bundled-helper `SMAppService` packaging until there is a clear product reason to own the entire install surface inside the app

That is the simplest path that strengthens the core model instead of producing another narrow stopgap.
