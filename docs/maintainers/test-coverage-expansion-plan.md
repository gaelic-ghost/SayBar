# Test Coverage Expansion Plan

## Purpose

This plan records the next testing sequence for SayBar after adding the shared `SayBar.xctestplan`.

Apple's Xcode testing guidance frames test plans as the scheme-level document that declares which test targets and configurations run for a test action, including command-line use through `xcodebuild -showTestPlans` and `xcodebuild test -testPlan ...`. Apple's broader testing guidance recommends a pyramid shape: many fast unit tests, fewer integration tests, and UI tests for common user flows.

For SayBar, that means the next coverage work should stay foundation-first:

- cover app-local logic that can be tested quickly and deterministically
- cover the implemented embedded-session behavior without adding a second app-owned server model
- review and streamline menu/settings view implementation before investing in deeper UI automation
- add Settings and UI coverage only after the UI surface is simpler and more testable

References:

- [Apple: Improving code assessment by organizing tests into test plans](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)
- [Apple: Testing](https://developer.apple.com/documentation/xcode/testing)
- [Apple: XCTest](https://developer.apple.com/documentation/xctest/)

## Current Baseline

The checked-in `SayBar` test plan includes:

- `SayBarTests`
- `SayBarUITests`
- one configuration named `Test Scheme Action`
- `SayBar` as the variable-expansion target

Current test coverage is intentionally narrow:

- `SayBarAppEnvironmentTests` covers autostart argument parsing and runtime profile-root resolution
- `MenuBarDisplaySupportTests` covers menu status priority, playback and runtime status wording, queue-slot clamping, selected voice fallback, and control symbol selection
- `MenuBarActionSupportTests` covers implemented menu action routing for resident model power actions, playback actions, voice-profile refresh, default voice selection, backend switching, and clipboard speech submission
- `SettingsDisplaySupportTests` covers Settings transport summary formatting
- `SayBarUITests` covers launch and termination with embedded autostart disabled
- `SayBarUITestsLaunchTests` covers relaunch after termination with embedded autostart disabled

The current UI tests deliberately avoid booting the full embedded runtime on every app-shell test run. Foundation display tests stay in `SayBarTests` so status wording and summary formatting can be verified without launching the app shell or the embedded runtime.

## Expansion Sequence

### Phase 1: Foundation Tests

Goal: cover app-owned logic that should never require a running speech runtime.

Planned coverage:

- keep `SayBar.xctestplan` as the default test plan for the `SayBar` scheme
- verify the test plan remains discoverable with `xcodebuild -showTestPlans -project SayBar.xcodeproj -scheme SayBar`
- expand `SayBarAppEnvironmentTests` around launch-argument behavior and runtime profile path construction
- add focused tests for app status mapping once status wording is factored into a small testable unit: done for menu status headline/detail
- add focused tests for queue-count clamping once queue display mapping is factored into a small testable unit: done for menu queue slots
- add focused tests for transport summary formatting once the Settings transport summary is factored into a small testable unit: done
- add focused tests for recent-error precedence once menu status selection is factored into a small testable unit: done for headline and detail precedence

Implementation notes:

- keep these tests in `SayBarTests`
- prefer simple XCTest cases unless the repo intentionally migrates unit tests to Swift Testing
- keep extracted units app-local and small; do not introduce a second runtime controller, session wrapper, or mirrored server-state model
- prefer pure formatting, mapping, and decision helpers over UI-hosted assertions

### Phase 2: Implemented Embedded Session Coverage

Goal: cover every `EmbeddedServer` surface SayBar already uses, without widening into standalone-server behavior.

Planned coverage:

- embedded lifecycle startup path: `SayBarApp` calls `liftoff()` when autostart is enabled
- embedded lifecycle disabled path: `SayBarApp` does not call `liftoff()` when `--saybar-disable-autostart` is present
- quit path: termination requests `land()` when autostart was enabled
- voice profile refresh path: empty profile cache triggers `refreshVoiceProfiles()`
- voice selection path: picker selection calls `setDefaultVoiceProfileName(_:)`
- backend selection path: picker selection calls `switchSpeechBackend(to:)`
- resident model power path: unloaded models call `reloadModels()`, loaded models call `unloadModels()`: command routing covered
- playback button path: playing calls `pausePlayback()`, paused calls `resumePlayback()`, idle submits clipboard speech: command routing covered
- clipboard speech path: empty clipboard reports a local message; non-empty clipboard calls `queueLiveSpeech(text:)`: covered through the local menu action seam
- observable state consumption: menu and Settings read `overview`, `generationQueue`, `playbackQueue`, `playback`, `runtimeConfiguration`, `voiceProfiles`, `transports`, and `recentErrors` directly

Implementation notes:

- add test seams only where the current direct `EmbeddedServer` baseline cannot otherwise be observed: currently `MenuBarActionSupport` accepts async closures for the real server calls while `MenuBarExtraWindow` keeps direct `EmbeddedServer` ownership
- if a seam is needed, keep it as a local implementation detail for app action testing, not as a new app-owned runtime model
- do not adopt `ServerInstallLayout`, `ServerInstalledLogs`, LaunchAgent install helpers, or standalone-server paths in this phase
- runtime-on integration tests should be explicit and isolated from the existing autostart-disabled shell UI tests

### Phase 3: UI Implementation Review And Streamlining

Goal: simplify the UI source shape before adding deeper Settings and menu automation.

Review targets:

- `SayBar/Scenes/Main/MenuBarExtraWindow.swift`
- `SayBar/Scenes/Main/MenuBarExtraWindow+Components.swift`
- `SayBar/Scenes/Settings/SettingsWindow.swift`
- `SayBar/Scenes/Settings/SettingsWindow+Sections.swift`

Planned cleanup:

- move status wording, symbol selection, and queue display mapping into small app-local helpers that can be unit tested
- keep SwiftUI views focused on layout and binding
- keep menu bar quick actions distinct from Settings diagnostics
- remove repeated formatting logic from views when a tiny pure helper can carry it
- keep accessibility identifiers stable for existing and future UI tests
- avoid adding coordinators, command buses, or wrapper models around `EmbeddedServer`

Exit criteria:

- the menu window view is mostly layout plus direct action callbacks
- Settings sections are mostly layout plus already-computed display values
- pure display decisions have unit coverage before UI automation depends on them

### Phase 4: Settings And UI Coverage

Goal: add UI and Settings tests after the UI implementation is simpler.

Planned coverage:

- Settings opens reliably from the app shell
- Settings app section displays version, embedded autostart state, and menu bar insertion state
- Runtime section displays status, worker stage, playback, speech backend, default voice profile, generation queue count, and playback queue count
- Transport section renders empty and populated transport states
- Recent errors section renders empty and populated error states
- menu surface exposes stable accessibility identifiers for status, queue, controls, and picker rows
- menu quick actions remain available without layout regressions

Implementation notes:

- keep existing launch/termination UI tests as shell smoke tests
- only add menu-bar traversal tests after the current `MenuBarExtra` accessibility boundary is re-reviewed
- prefer unit tests for display decisions and use UI tests only for app-level presentation and common workflows

## Out Of Scope For This Expansion

- app-managed standalone-server install mode
- retained standalone stdout/stderr log UI
- LaunchAgent install, enable, disable, or uninstall workflows
- monorepo submodule adoption coverage
- broad visual snapshot testing

## Validation Commands

Use the test plan explicitly when validating this work:

```sh
xcodebuild -showTestPlans -project SayBar.xcodeproj -scheme SayBar
xcodebuild -project SayBar.xcodeproj -scheme SayBar test -testPlan SayBar
```

Keep Xcode and SwiftPM validation serialized on this machine.
