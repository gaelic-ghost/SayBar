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
- explicit accessibility identifiers on `MenuBarExtraWindow` root content and key controls

Relevant source files:

- `SayBar/SayBarApp.swift`
- `SayBar/Views/MenuBarExtraWindow.swift`
- `SayBarUITests/SayBarUITests.swift`

### Menu window freeze root-cause finding

The menu bar window freeze turned out not to be a generic `MenuBarExtra(.window)` problem and not a generic layout problem.

The stable-versus-unstable boundary was:

- header-only content: stable
- header plus metrics rows with static literal values: stable
- header plus the same metrics rows reading live nested `ServerState` properties from the view body: unstable under Xcode, typically freezing with `EXC_BAD_ACCESS`

The important architecture lesson is that `MenuBarExtraWindow` should not reach through `ssController.serverState` and then traverse the nested live `ServerState` graph directly while SwiftUI is constructing the menu window scene.

The current stable fix is:

- keep one app-owned `SpeakSwiftlyController` in `@State` at the app boundary
- flatten menu-facing metrics onto `SpeakSwiftlyController` as an app-facing snapshot
- have `MenuBarExtraWindow` render that flattened controller snapshot instead of directly reading `ServerState`

This keeps the menu window reading one app-facing observable surface instead of conditionally traversing a second observable object through a computed property during view construction.

### What XCUITest can currently do

The current real-path UI test findings are:

- the menu bar status item is discoverable from macOS XCUITest when SayBar uses the custom `label:` initializer
- the status item is clickable from XCUITest
- the current test can wait for and interact with the real menu bar item identified as `saybar-menu-bar-extra`

### What still fails

After clicking the real status item, the `.menuBarExtraStyle(.window)` content still does not currently appear in the expected XCUITest accessibility tree.

That means the current failure boundary is narrower than "the window content has no accessibility metadata." The current app already exposes accessibility identifiers such as:

- `saybar-menu-window`
- `saybar-status-headline`
- `saybar-status-detail`
- `saybar-primary-action`
- `saybar-stop`
- `saybar-open-settings`

The more likely boundary is the system-managed handoff between the menu bar status item and the opened window-style presentation.

## Comparison Checklist

Use this checklist when comparing SayBar with other menu bar apps:

1. How is the status item exposed to accessibility?
   - Is it an `AXMenuBarItem`?
   - Does it report `AXMenuExtra` as the subrole?
   - Does it have a visible label, title, or app-specific identifier?

2. What kind of opened surface appears after selection?
   - A SwiftUI window-style extra
   - An AppKit popover window
   - A panel or custom window

3. Where does the opened surface appear in accessibility inspection?
   - Under the app hierarchy
   - As a separate popover/window object
   - Under a different process or system-owned tree than expected

4. What feels different to the user?
   - Corner radius and pointer notch
   - Spacing and window chrome
   - Whether the surface feels like a standard system extra or a custom popover

5. What does that difference probably mean?
   - style-only variation inside the same architecture
   - different automation behavior with the same broad scene type
   - a real AppKit-versus-SwiftUI presentation difference

## Reference Comparison Notes

### SayBar

- current presentation model: SwiftUI `MenuBarExtra(...).menuBarExtraStyle(.window)`
- status item: currently discoverable and clickable from XCUITest after switching to the custom `label:` initializer
- opened surface: still not visible where the current XCUITest expects the root `saybar-menu-window` element

### PCalc

The inspected PCalc surface suggests a more AppKit-like popover implementation:

- the status item appears as `AXMenuBarItem`
- the subrole appears as `AXMenuExtra`
- the opened surface appears as a popover window object, specifically `[_NSPopoverWindow]`

That strongly suggests PCalc is not simply showing a default SwiftUI `MenuBarExtra(.window)` presentation. It looks more like an app-owned popover window path.

### Passwords

The inspected Passwords menu bar surface currently suggests a more system-standard extra:

- the status item also appears as `AXMenuBarItem`
- the subrole also appears as `AXMenuExtra`
- the status item title appears as `apple.passwords`
- in the captured inspection, the status item is visible clearly, but the opened locked surface is not called out in the same obviously custom way as PCalc's explicit `[_NSPopoverWindow]`

That makes Passwords a useful comparison point for "system-standard menu bar extra behavior" rather than "custom popover behavior."

## Current Recommendation

Treat the current SayBar automation problem as a system-presentation boundary first, not as missing accessibility identifiers on the content view.

Only reach for a debug-only or test-only host for `MenuBarExtraWindow` if we explicitly decide that:

- reliable CI coverage of the menu bar content matters more than proving the exact real menu bar transition path
- and we are comfortable recording that as a deliberate testing tradeoff instead of pretending it validates the full production interaction

## Runtime And Sandbox Findings

This section captures the current runtime findings that sit adjacent to menu bar validation, because they affect how SayBar behaves when launched from Xcode during UI and integration work.

### Embedded startup isolation finding

Current Xcode launches split cleanly into two behaviors:

- when SayBar launches with embedded autostart enabled, runtime diagnostics appear during startup
- when SayBar launches with `--saybar-disable-autostart`, the app shell, menu bar scene registration, and ordinary app lifecycle behavior appear without those runtime diagnostics

That means the current noisy diagnostics are tied to embedded runtime startup, not to basic `MenuBarExtra` scene creation.

### Current ownership and actor-boundary finding

The current embedded-session shape is:

- app-owned controller in `SayBar/SayBarApp.swift`
- one app-wide `SpeakSwiftlyController`
- one optional `EmbeddedServerSession` owned by that controller
- one app-facing `ServerState`
- one actor-owned `ServerHost` and task-driven `SpeakSwiftly` runtime underneath

The app-facing wrapper is currently more main-actor-shaped than the underlying host:

- `SpeakSwiftlyController` is `@MainActor`
- `EmbeddedServerSession` is `@MainActor`
- `ServerState` is `@MainActor`
- `ServerHost` is an actor and already performs status, publish, prune, and config-watch work through background tasks

That makes the current question narrower than "is everything on the main thread?" The better question is which bootstrap steps still need main-actor isolation and which should move behind a non-main startup boundary while preserving the same ownership model.

### Current playback finding

The current local playback path is intentionally more main-actor-bound than the rest of the runtime:

- `SpeakSwiftly` currently builds the playback controller through a `@MainActor` dependency hook
- `AudioPlaybackDriver` is itself `@MainActor`
- the driver owns `AVAudioEngine`, routing arbitration, and `NSWorkspace`-driven environment observation

So any future "move startup off main actor" work must distinguish:

- UI-facing wrapper and observable-state isolation
- truly concurrent host and runtime startup work
- playback-driver work that may legitimately remain main-actor-bound because of AppKit and AVFoundation behavior

The current startup-pop investigation also has a concrete lead now:

- resident preload in `SpeakSwiftly` currently calls `playbackController.prepare(...)`
- `AudioPlaybackDriver.prepare(...)` will rebuild the engine when needed
- `rebuildEngine(sampleRate:)` tears down playback hardware, begins macOS routing arbitration, constructs a new `AVAudioEngine`, starts the engine, and immediately calls `AVAudioPlayerNode.play()`

That means the audio pops heard at SayBar startup are currently most plausibly tied to eager playback-engine bring-up during resident preload, not to the menu bar window anymore.

### Current Xcode runtime-warning finding

The current warning cluster seen under Xcode launch includes:

- Security diagnostics about work that should not happen on the main thread
- a sandbox precondition mentioning `com.apple.audioanalyticsd`
- Core Audio and `AVAudioEngine` startup noise immediately after embedded autostart begins

These warnings still need to be re-checked after the next `SpeakSwiftlyServer` bootstrap cleanup pass. They are currently recorded as "runtime-startup warnings under embedded autostart," not yet as a settled bug with a final root-cause writeup.

### Current sandbox-verification finding

The current repo does not have a checked-in `.entitlements` file, so effective sandbox verification must be done from the signed product, not by inspecting a source entitlement file in the repo.

The last inspected signed SayBar products showed:

- `com.apple.security.app-sandbox`
- `com.apple.security.network.server`
- but not `com.apple.security.network.client`

Because Gale had already enabled the client entitlement in Xcode, treat that as a "rebuild and re-verify" gap first, not as proof that the capability change failed.

### Current follow-up checklist

Before the next SayBar-versus-`SpeakSwiftlyServer` integration review, re-check these items:

1. Does the freshly signed SayBar app now include both network client and network server entitlements?
2. Do the current Xcode runtime warnings still reproduce after the latest `SpeakSwiftlyServer` bootstrap changes?
3. If they still reproduce, which warning belongs to playback-driver startup versus earlier host bootstrap work?
4. Can more embedded-session bootstrap work move off the main actor without changing the app-wide ownership model?
