# ADR-0001: Keep The Direct EmbeddedServer App Baseline

## Status

Accepted

## Context

SayBar is a native macOS menu bar app that sits in front of `SpeakSwiftlyServer`.

The package now exposes `EmbeddedServer` as its app-facing `@Observable` embedding surface. That model already owns:

- embedded lifecycle entrypoints such as `liftoff()` and `land()`
- observable runtime snapshots for overview, queues, playback, runtime configuration, transports, and recent errors
- direct app-host control actions for voice profiles, backend switching, model reload and unload, playback control, and live speech submission

Earlier SayBar planning discussed app-owned controller and session-wrapper shapes, but those layers became redundant once the package surface stabilized around direct `EmbeddedServer` ownership.

## Decision

SayBar keeps one app-owned `EmbeddedServer` as the product baseline.

The app:

- stores that observable model in SwiftUI state
- starts it on launch unless autostart is explicitly disabled for tests or debugging
- requests `land()` before app termination completes
- binds menu bar and settings UI directly to the package-owned observable properties

SayBar does not add a second app-owned controller, session wrapper, or mirrored runtime-state model on top of `EmbeddedServer`.

## Consequences

This keeps the app boundary flat and easier to reason about:

- package-owned runtime state stays package-owned
- SayBar can focus on menu bar presentation, settings diagnostics, and native macOS affordances
- docs and tests can describe one app-owned model instead of multiple overlapping ownership layers

The newer `ServerInstallLayout` and `ServerInstalledLogs` helper APIs in `SpeakSwiftlyServer` remain available for future product work, but they are not part of the current SayBar baseline until the app intentionally grows a standalone-server mode.
