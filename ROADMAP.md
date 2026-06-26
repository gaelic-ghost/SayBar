# ROADMAP

## Table of Contents

- [Vision](#vision)
- [Product Principles](#product-principles)
- [Milestone Progress](#milestone-progress)
- [Milestone 1: App Shell Foundation And Service-Hosting Boundaries](#milestone-1-app-shell-foundation-and-service-hosting-boundaries)
- [Milestone 2: Status-Driven Menu Bar Experience](#milestone-2-status-driven-menu-bar-experience)
- [Milestone 3: Settings, Diagnostics, And Operator Workflow](#milestone-3-settings-diagnostics-and-operator-workflow)
- [Milestone 4: Release And Monorepo Integration Discipline](#milestone-4-release-and-monorepo-integration-discipline)
- [Milestone 5: Foundation And Embedded-Session Test Coverage](#milestone-5-foundation-and-embedded-session-test-coverage)
- [Milestone 6: Project Generation And Build Settings Hygiene](#milestone-6-project-generation-and-build-settings-hygiene)
- [Milestone 7: Browser Page Capture](#milestone-7-browser-page-capture)
- [Small Tickets](#small-tickets)
- [Backlog Candidates](#backlog-candidates)
- [History](#history)

## Vision

- Build SayBar into a reliable macOS menu bar control surface for speech service lifecycle, status, diagnostics, browser capture, and settings without re-implementing server responsibilities inside the app repo.

## Product Principles

- [ ] Keep the app lightweight, always-available, and easy to understand at a glance.
- [ ] Keep service ownership boundaries honest between SayBar and its sibling service repositories.
- [ ] Prefer clear status and operator diagnostics over decorative interface work.
- [ ] Preserve release discipline between the standalone app repo and any future monorepo submodule adoption.
- [ ] Keep browser capture explicit, user-initiated, and privacy-aware.

## Milestone Progress

- Milestone 1: App Shell Foundation And Service-Hosting Boundaries - Completed
- Milestone 2: Status-Driven Menu Bar Experience - Completed
- Milestone 3: Settings, Diagnostics, And Operator Workflow - In Progress
- Milestone 4: Release And Monorepo Integration Discipline - Planned
- Milestone 5: Foundation And Embedded-Session Test Coverage - In Progress
- Milestone 6: Project Generation And Build Settings Hygiene - Completed
- Milestone 7: Browser Page Capture - In Progress

## Milestone 1: App Shell Foundation And Service-Hosting Boundaries

### Status

Completed

### Scope

- [x] Stabilize the standalone macOS app shell.
- [x] Replace scaffold UI with real app-owned state and service hooks.
- [x] Document the app's development and integration boundaries clearly.

### Tickets

- [x] Keep a standalone Xcode app target with `SayBar`, `SayBarTests`, and `SayBarUITests`.
- [x] Wire the project to the `SpeakSwiftlyServer` package product used by the app shell.
- [x] Keep repo-facing docs (`README.md`, `ROADMAP.md`, `AGENTS.md`) tracked in the project.
- [x] Replace scaffold text in the menu bar and settings views with app-owned UI structure.
- [x] Introduce the first real service supervision path from the app shell into sibling services.

### Exit Criteria

- [x] The app surfaces real status instead of scaffold text.
- [x] The first hosted-service integration path is documented and implemented without duplicate service logic in the app repo.
- [x] The standalone repo docs accurately describe the app's role and current state.

## Milestone 2: Status-Driven Menu Bar Experience

### Status

Completed

### Scope

- [x] Build the quick-action and status surface that Gale can rely on from the menu bar.

### Tickets

- [x] Define app-level service states such as stopped, starting, ready, degraded, and broken.
- [x] Present those states clearly in the menu bar UI.
- [x] Add quick actions for the most common operator workflows.
- [x] Add human-friendly error and warning strings for failed or degraded states.

### Exit Criteria

- [x] Gale can tell the current service state with minimal interaction.
- [x] The menu bar surface supports the core day-to-day control flow without opening Settings.

## Milestone 3: Settings, Diagnostics, And Operator Workflow

### Status

In Progress

### Scope

- [ ] Move deeper configuration and diagnostics into the Settings experience.
- [ ] Keep the embedded runtime operator surface grounded while hardening the accepted direct-`EmbeddedServer` product model.

### Tickets

- [x] Keep app persistence narrow and app-owned instead of mirroring sibling-service runtime state locally.
- [x] Host the embedded `SpeakSwiftlyServer` runtime through one app-owned `EmbeddedServer` model.
- [x] Surface runtime, playback, transport, and diagnostics sections in Settings.
- [x] Build settings sections for configuration that genuinely belongs to the macOS app.
- [x] Add diagnostics surfaces for logs, startup failures, and likely-cause messaging.
- [ ] Verify the tabbed Settings diagnostics view against live embedded-runtime, playback, queue, and configuration states.
- [x] Choose and document the long-term direct-embedding product baseline for App Store-compatible delivery.
- [ ] Verify launch, relaunch, and quit behavior for background work.

### Exit Criteria

- [x] Settings owns deeper configuration and diagnostics cleanly.
- [x] Operator-facing failures are specific, readable, and actionable.
- [x] The current embedded runtime operator surface is implemented and documented.
- [x] The app's product-baseline process-ownership model is explicit.
- [ ] App lifecycle behavior is explicit across launch and shutdown.

## Milestone 4: Release And Monorepo Integration Discipline

### Status

Planned

### Scope

- [ ] Keep standalone releases and future `speak-to-user` integration predictable.

### Tickets

- [ ] Tag standalone SayBar releases from this repository.
- [ ] Prefer monorepo adoption through pinned submodule releases instead of arbitrary branch tips.
- [ ] Land monorepo pointer bumps and umbrella-doc updates through pull requests.
- [ ] Keep umbrella docs explicit about whether SayBar is still sibling-hosted or vendored as a submodule.

### Exit Criteria

- [ ] Standalone app releases remain the source of truth.
- [ ] Monorepo integration work follows an isolated worktree and PR-based flow.

## Milestone 5: Foundation And Embedded-Session Test Coverage

### Status

In Progress

### Scope

- [ ] Expand test coverage in the order that keeps SayBar easiest to reason about: foundation tests first, implemented embedded-session behavior next, UI implementation streamlining before deeper Settings and UI automation coverage.

### Tickets

- [x] Add a checked-in `SayBar.xctestplan` and wire it to the shared `SayBar` scheme.
- [x] Add focused foundation tests for menu status mapping, queue display mapping, control symbols, selected voice fallback, and Settings transport summaries.
- [ ] Expand app-foundation tests for environment parsing, profile path construction, status mapping, queue display mapping, transport summaries, and recent-error precedence.
- [x] Cover implemented embedded-session actions for lifecycle, voice refresh, default voice selection, backend switching, resident model reload/unload, playback pause/resume, and clipboard speech submission.
- [ ] Review and streamline menu and Settings view implementations before adding deeper UI assertions.
- [ ] Verify menu surface navigation with hands-on two-finger backward and forward swipe gestures over the menu bar window.
- [ ] Add Settings and menu bar UI coverage after the view implementations are simpler and more testable.

### Exit Criteria

- [ ] `xcodebuild -showTestPlans -project SayBar.xcodeproj -scheme SayBar` reports the checked-in `SayBar` test plan.
- [ ] `xcodebuild -project SayBar.xcodeproj -scheme SayBar test -testPlan SayBar` is the documented baseline test command.
- [x] Implemented embedded-session behavior has focused coverage without adding a second app-owned runtime model.
- [ ] UI coverage starts from a streamlined, stable menu and Settings implementation.

## Milestone 6: Project Generation And Build Settings Hygiene

### Status

Completed

### Scope

- [x] Move project shape and shared build settings toward plain-text sources of truth without disrupting the current Xcode app workflow.

### Tickets

- [x] Plan the staged XcodeGen and xcconfig migration in maintainer docs.
- [x] Add a `project.yml` that models the current app, unit-test, and UI-test targets.
- [x] Add checked-in xcconfig coverage for shared build settings.
- [x] Regenerate `SayBar.xcodeproj` from XcodeGen and review the generated diff against the current project contract.
- [x] Add repo-maintenance validation that detects generated-project drift.

### Exit Criteria

- [x] Project shape is reviewable in `project.yml`.
- [x] Shared build settings are reviewable in checked-in xcconfig files.
- [x] The generated Xcode project builds and unit-style tests pass through the documented `SayBar` scheme.
- [x] Repo-maintenance validation catches stale generated project output.

## Milestone 7: Browser Page Capture

### Status

In Progress

### Scope

- [ ] Add user-initiated browser page capture that turns readable page structure into speech input and queues it through SayBar without adding a second runtime owner.

### Tickets

- [x] Add a shared WebExtension core and Safari Web Extension wrapper target.
- [x] Add SwiftSoup as an explicit SayBar dependency for native browser-capture formatting.
- [x] Convert captured browser HTML into Markdown-oriented speech text before queueing.
- [x] Send Safari WebExtension native messages through the Safari extension handler.
- [x] Queue formatted browser capture text through SayBar's embedded runtime transport with lean request context.
- [ ] Add Chrome, Firefox, and Zen packaging adapters after the shared capture contract is stable.

### Exit Criteria

- [ ] Safari can capture the active page text by explicit user action and queue it for live speech.
- [ ] Browser capture request context uses only relevant source, topic, and browser-origin attributes.
- [ ] Page text and URLs are not logged as full request bodies.
- [ ] Cross-browser adapter decisions are documented without adding browser-specific duplicate capture logic.

## Small Tickets

- [ ] Add a non-audible embedded lifecycle verification pass for launch and graceful `land()` shutdown if `SpeakSwiftlyServer` exposes a stable lightweight test runtime mode. Source: `TODO.md`.
- [ ] Keep the `.menuBarExtraStyle(.window)` UI-test boundary under review and keep deeper menu-surface traversal on deterministic launch state until gesture automation is reliable enough for routine validation. Source: `FIXME.md`.

## Backlog Candidates

- [ ] Revisit whether SayBar should adopt `SpeakSwiftlyServer` standalone-install and retained-log helper APIs when the product intentionally grows an app-managed standalone-server mode. Source: `TODO.md`.
- [ ] Consider App Groups for browser-extension/app handoff later if native messaging plus the embedded runtime transport stops fitting the product boundary.

## History

- 2026-06-26: Migrated the legacy roadmap, TODO, and FIXME surfaces into the canonical checklist roadmap structure.
- 2026-06-26: Added browser page capture as an in-progress milestone for the Safari Web Extension branch.
- 2026-06-26: Added Safari native-message queueing with SwiftSoup-backed Markdown formatting and lean browser-origin request context.
- Earlier roadmap history lives in the Git history before the canonical roadmap migration.
