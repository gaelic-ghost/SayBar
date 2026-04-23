# Accessibility And UI Automation Notes

## Purpose

This document collects the current accessibility and UI-automation findings for SayBar's menu bar surface in one place.

Use it when:

- evaluating whether the current `MenuBarExtra` presentation is testable enough as-is
- deciding whether a future AppKit popover path is about styling, accessibility behavior, or a real architecture change
- comparing SayBar's current surface to other macOS menu bar apps

## Current SayBar Findings

### Current implementation shape

The current app uses:

- `MenuBarExtra(isInserted:content:label:)`
- a custom SwiftUI `Label` view for the real menu bar item label
- `.menuBarExtraStyle(.window)` for the opened surface
- one app-owned `EmbeddedServer` created in `SayBarApp`
- composable SwiftUI subviews inside `MenuBarExtraWindow`

Relevant source files:

- `SayBar/SayBarApp.swift`
- `SayBar/Scenes/Main/MenuBarExtraWindow.swift`
- `SayBar/Scenes/Settings/SettingsWindow.swift`
- `SayBarUITests/SayBarUITests.swift`

### Current architecture lesson

The old controller-era guidance in this repo is obsolete now.

SayBar no longer keeps:

- an app-owned `SpeakSwiftlyController`
- an optional `EmbeddedServerSession`
- an app-owned `ServerState` wrapper

The current stable rule is simpler:

- keep one app-owned `EmbeddedServer` at the app boundary
- let views read that same `EmbeddedServer` directly
- keep view-local state limited to transient action feedback and busy flags

### What XCUITest can currently do

The checked-in UI test target currently follows Apple's documented `XCUIApplication` launch and state-wait pattern.

The current checked-in tests validate these shell-level behaviors with `--saybar-disable-autostart`:

- initial launch completes
- explicit app termination completes
- the app can relaunch after termination

That test shape keeps the UI suite aligned with the supported XCUITest surface while avoiding a full embedded-runtime bootstrap in every UI test run.

The repo currently does not keep a checked-in UI test that clicks and traverses the real menu bar extra content.

### What still fails

Earlier interactive inspection showed that the `.menuBarExtraStyle(.window)` content still does not appear in the expected XCUITest accessibility tree after selecting the real status item.

That means the current failure boundary is the system-managed handoff between the menu bar item and the opened window-style presentation, not missing accessibility identifiers on the SwiftUI content itself.

## Current Recommendation

Treat the current SayBar automation problem as a system-presentation boundary first, not as missing metadata on the content view.

For the current repo state, the honest validation split is:

- unit tests are minimal because the app no longer keeps a separate presentation layer over the server model
- UI tests cover launch, termination, and relaunch behavior without embedded autostart
- real menu bar content automation remains an open investigation rather than a stable checked-in guarantee

## Runtime And Sandbox Findings

### Embedded startup isolation finding

Current Xcode launches split cleanly into two behaviors:

- when SayBar launches normally, the embedded runtime starts during app launch
- when SayBar launches with `--saybar-disable-autostart`, the app shell launches without embedded runtime startup

That means the autostart toggle remains useful for shell-focused UI tests and shell-level debugging.

### Current quit-path finding

The app now requests embedded-runtime shutdown through `EmbeddedServer.land()` before allowing macOS termination to finish.

That makes the launch and quit ownership story explicit in app code even though the UI test target still exercises the lighter autostart-disabled path.

### Current ownership finding

The current embedded app shape is:

- one app-owned `EmbeddedServer` in `SayBarApp`
- menu bar and settings scenes that both read that same object directly
- small view-local state only for transient action feedback and busy flags

The app-facing model is now exactly the package-owned observable object rather than a second app-owned wrapper.

### Current sandbox-verification finding

The current repo does not have a checked-in `.entitlements` file, so effective sandbox verification must still be done from the signed product, not by inspecting a source entitlement file in the repo.

### Current clipboard speech finding

The menu bar clipboard button now uses `EmbeddedServer.queueLiveSpeech(...)` directly.

That keeps the menu bar surface on the same embedded control path as the other runtime actions instead of routing clipboard speech through a local HTTP fallback.
