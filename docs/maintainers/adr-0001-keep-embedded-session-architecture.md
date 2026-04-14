# ADR 0001: Keep The Embedded Session Architecture As The Product Baseline

## Status

Accepted on 2026-04-14.

## Context

SayBar currently hosts `SpeakSwiftlyServer` inside the app process through the server package's embedded-session API. That implementation is already the repo's current source of truth:

- the app creates one `SpeakSwiftlyController`
- the controller starts one `EmbeddedServerSession`
- the menu bar and Settings surfaces read app-facing state from the embedded server session
- the standalone repository documents this embedded-session path as the active architecture

The open product question has been whether SayBar should remain embedded-first or pivot toward a more optional controller model that attaches to a separately running `SpeakSwiftlyServer`, potentially with launch-agent-backed service ownership.

That question now needs an explicit decision because App Store compatibility changes the tradeoffs.

Apple's current documented constraints are the important baseline:

- Mac App Store apps must enable App Sandbox.
- In macOS 13 and later, Apple documents `SMAppService` as the supported API for login items, launch agents, and launch daemons that belong to an app bundle.
- Apple documents `SMAppService` registration as the replacement for installing launch-agent property lists into `~/Library/LaunchAgents` or `/Library/LaunchAgents`.
- Apple documents bundled helper executables and bundled launch-agent property lists as the modern service-management structure for app-owned helpers.

Relevant Apple documentation:

- [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
- [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Updating helper executables from earlier versions of macOS](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- [Updating your app package installer to use the new Service Management API](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api)

Inside SayBar's option space, that creates a meaningful split:

- embedded in-process hosting is a straightforward sandboxed app story
- a bundled helper registered with `SMAppService` is the Apple-native out-of-process app-owned helper story
- an external launch-agent install story delegated to `SpeakSwiftlyServer` remains practical for direct distribution, but it is not the preferred Apple-native helper model for an App Store-facing app

## Decision

Keep the embedded-session architecture as SayBar's product baseline.

Treat the current embedded in-process session model as the default and App-Store-aligned architecture for the standalone SayBar app repository.

Do not widen SayBar toward an attached external-service controller model, remote-session backend, or launch-agent installation UI as part of the default product architecture at this stage.

If a future product requirement appears that truly requires the speech service to outlive the app UI process, revisit the architecture as a deliberate bundled-helper `SMAppService` project instead of first moving through a legacy external launch-agent controller phase.

## Consequences

### Positive

- SayBar keeps one clear process-ownership model: the app owns the UI lifecycle and hosts one embedded `SpeakSwiftlyServer` session in-process.
- The architecture remains aligned with the current implementation and current repo docs instead of drifting into a second partially adopted model.
- The App Store story stays cleaner because the app remains a sandboxed single-product surface without an external installation contract.
- Near-term work can focus on lifecycle hardening, diagnostics, and release discipline instead of transport and helper-install complexity.

### Negative

- The speech runtime does not continue independently when SayBar exits.
- SayBar does not become a general-purpose controller for an already-installed external `SpeakSwiftlyServer`.
- If the product later needs background persistence outside the app process, a more substantial packaging and signing pass will still be required.

### Deferred

The following paths remain deliberately deferred rather than rejected forever:

- a bundled app-owned helper executable and bundled launch agent managed through `SMAppService`
- a non-default optional controller mode that attaches to an external server for direct-distribution workflows

Those are future product decisions, not follow-up tasks implied by this ADR.

## What This Changes In Practice

The next architecture and product work should stay centered on the embedded model:

- verify launch, relaunch, and quit behavior for the embedded session
- confirm the app does not create duplicate embedded sessions during restart or relaunch flows
- keep persistence narrow and app-owned
- continue improving operator diagnostics and status vocabulary
- keep standalone release and monorepo integration discipline explicit

The following work is out of scope unless product requirements change:

- building a remote-session HTTP client in SayBar
- adding an attached-mode backend to `SpeakSwiftlyController`
- adding launch-agent install, uninstall, or repair UI to SayBar
- treating the external-launch-agent path as the default evolution of the product

## Related Documents

- [docs/maintainers/embedded-session-integration-plan.md](embedded-session-integration-plan.md)
- [docs/maintainers/controller-architecture-options.md](controller-architecture-options.md)
