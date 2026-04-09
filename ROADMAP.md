# ROADMAP

## Vision

Build a native macOS menu bar app that gives Gale a straightforward, reliable, and aesthetically pleasing control surface for local speech services, with SayBar hosting and supervising the SpeakSwiftly server and MCP libraries while keeping status, configuration, and operator actions close at hand.

## Product principles

- [ ] Keep the app local-first and explicit about what is running on the machine.
- [ ] Make service state legible from the menu bar without requiring terminal inspection.
- [ ] Prefer direct SwiftUI and macOS architecture over unnecessary wrappers or duplicate service layers.
- [ ] Keep server-hosting responsibilities inside the sibling SpeakSwiftly libraries where possible, with SayBar acting as the app shell and controller.
- [ ] Ship user-facing errors, warnings, and logs that explain what broke, where, and at least one likely cause.

## Milestone Progress

- [ ] Milestone 1: Replace the Xcode template shell with a real SayBar app skeleton.
- [ ] Milestone 2: Add a basic placeholder UI and verify app build and launch behavior.
- [ ] Milestone 3: Integrate local SpeakSwiftly server and MCP libraries.
- [ ] Milestone 4: Add playback controls, server status, queue status, and settings flows.
- [ ] Milestone 5: Harden packaging, release, and monorepo adoption.

## Milestone 1: Real app shell

### Scope

Turn the current placeholder `MenuBarExtra` project into a recognizably real SayBar app with stable names, structure, and baseline windows.

### Tickets

- [ ] Replace placeholder menu bar title and symbol strings in `SayBarApp`.
- [ ] Replace the placeholder `Hello, World!` menu bar and settings views with app-shaped scaffolding.
- [ ] Define the initial app-level state and scene structure for menu bar and settings flows.
- [ ] Flesh out `VoiceProfile` into a real persisted model only as far as the first app flows require.
- [ ] Add project documentation for purpose, setup, and roadmap.

### Exit criteria

- [ ] The app launches with SayBar-specific menu bar branding instead of template strings.
- [ ] The menu bar window and settings window both reflect the product direction.
- [ ] The repository no longer reads like an untouched Xcode starter app.

## Milestone 2: Placeholder UI and app viability

### Scope

Replace the remaining template feel with a basic placeholder UI and make sure the app has a reliable build-and-run loop before deeper integration work starts.

### Tickets

- [ ] Add a basic placeholder menu bar window layout that reflects the planned app sections.
- [ ] Add a basic placeholder Settings scene with app-shaped configuration groups.
- [ ] Replace any remaining template strings and placeholder branding leaks.
- [ ] Verify the `SayBar` scheme builds cleanly in Xcode.
- [ ] Verify the app launches, inserts into the menu bar, and opens both primary scenes.

### Exit criteria

- [ ] The menu bar UI is recognizably SayBar even if backend functionality is still stubbed.
- [ ] The Settings scene exists and opens reliably.
- [ ] The app has a documented and repeatable build-and-run workflow.

## Milestone 3: Local library integration

### Scope

Wire SayBar to the sibling `SpeakSwiftlyServer` and `SpeakSwiftlyMCP` repositories as the canonical hosting and control backends.

### Tickets

- [ ] Decide the package integration path for the sibling repositories and document it.
- [ ] Add package dependencies for the local SpeakSwiftly libraries through Xcode-safe project workflows.
- [ ] Define the minimal integration boundary between app UI, service hosting, and MCP control.
- [ ] [P] Identify shared models or status types that should stay in the sibling libraries instead of being recreated here.
- [ ] Add a development-time path for launching against local checkouts.

### Exit criteria

- [ ] SayBar builds with the intended SpeakSwiftly dependencies connected.
- [ ] The app has one clear, documented boundary for server and MCP control.
- [ ] There is no duplicate service-hosting architecture inside SayBar that belongs in the sibling libraries.

## Milestone 4: Controls, status, and settings flows

### Scope

Give the menu bar app enough behavior to expose playback controls, service state, queue visibility, and a useful Settings flow.

### Tickets

- [ ] Add playback controls for the first supported local playback actions.
- [ ] Add visible server status for readiness, degraded states, and recent failures.
- [ ] Add queue status display for pending, active, and completed work visibility.
- [ ] Decide what status and controls belong in the menu bar window versus Settings.
- [ ] Add human-readable operator messaging for control failures and integration errors.

### Exit criteria

- [ ] Playback controls are visible and the intended action plumbing is clear.
- [ ] Server status and queue status are legible from the app UI.
- [ ] Settings owns deeper configuration while the menu bar surface stays focused on quick control and status.

## Milestone 5: Hardening, release, and monorepo adoption

### Scope

Improve reliability, verification, and macOS polish so the app is safe to use as an everyday local controller, then adopt it cleanly into the umbrella workspace as a pinned app submodule.

### Tickets

- [ ] Define the real fields needed for stored voice profiles and app preferences.
- [ ] Decide what belongs in SwiftData versus what should stay in service-owned config.
- [ ] Add migration-safe persistence decisions before shipping real profile data.
- [ ] Expand unit and UI coverage beyond Xcode template tests.
- [ ] Verify menu bar behavior across launch, quit, relaunch, and settings flows.
- [ ] Review app logging, warnings, and failure modes for operator clarity.
- [ ] Keep repo guidance aligned with the installed Apple Dev Skills plugin workflow and skill names.
- [ ] Add release notes and packaging guidance for standalone SayBar tags.
- [ ] Add SayBar to `speak-to-user/apps` as a pinned submodule at a tagged release.
- [ ] Update umbrella docs so `speak-to-user` describes SayBar as a current vendored app submodule instead of only a sibling repository.
- [ ] Confirm the app degrades clearly when dependencies or local services are unavailable.

### Exit criteria

- [ ] Voice profiles and preferences have a clear persistence story.
- [ ] The verification story covers the core menu bar workflows.
- [ ] Operator-facing failures are actionable and specific.
- [ ] SayBar is usable as a day-to-day local speech control surface.
- [ ] The standalone repo and the umbrella workspace agree on SayBar's release and submodule adoption story.
