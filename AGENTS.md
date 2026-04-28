# SayBar Agent Notes

Use this file for durable repo-local guidance before changing code, docs, project configuration, or release workflow surfaces in this standalone SayBar repository.

## Repository Scope

### What This File Covers

- SayBar is a native macOS `MenuBarExtra` app built in Xcode.
- Treat the standalone `SayBar` repository as the source of truth for app development, tags, and releases.
- Treat `../speak-to-user/apps/SayBar` as the monorepo integration submodule copy once the umbrella workspace adopts it, not the primary development home.
- The intended role of this repository is to provide the app shell, menu bar UI, settings UI, and macOS-facing service control surface for `SpeakSwiftlyServer`.
- Treat sibling repositories as the primary homes for server and MCP behavior. SayBar should host, supervise, configure, and present them, not casually re-implement their responsibilities.

### Where To Look First

- Start with [README.md](README.md) for the current product shape, app architecture, setup, validation, and release entrypoints.
- Read [docs/maintainers/README.md](docs/maintainers/README.md) for the maintainer-doc index and recommended reading order.
- Use [docs/maintainers/adr-0001-keep-direct-embeddedserver-baseline.md](docs/maintainers/adr-0001-keep-direct-embeddedserver-baseline.md) and [docs/maintainers/embedded-server-ui-architecture.md](docs/maintainers/embedded-server-ui-architecture.md) as the current architecture records for direct `EmbeddedServer` ownership.
- Use `SayBar/SayBarApp.swift`, `SayBar/Scenes/Main/MenuBarExtraWindow.swift`, and `SayBar/Scenes/Settings/SettingsWindow.swift` as the main app-flow anchors.
- Use `scripts/repo-maintenance/` for local validation, shared sync, and release automation.

## Working Rules

### Change Scope

- Keep SwiftUI structure simple, top-down, and easy to reason about.
- Prefer small focused views and straightforward app state over extra coordinators, managers, wrappers, or duplicate model layers.
- New layers and dependencies are risky here unless they clearly remove complexity, so treat any new abstraction with strong caution and justify it before and after adding it.
- Keep dependency injection unidirectional. UI should depend on stable app-facing interfaces, and app-level integration should depend on sibling libraries rather than the other way around.
- Preserve clear ownership boundaries between menu bar UI, settings UI, persisted app state, and hosted service behavior.
- Use SwiftData only for state that genuinely belongs to the app. Do not mirror sibling-library state locally unless there is a concrete app-level reason.

### Source of Truth

- Prefer the repo-local Apple Dev Skills plugin workflow when it is installed here.
- For active Xcode execution work, use `Apple Dev Skills:xcode-app-project-workflow` as the top-level entry point.
- For Apple and Swift documentation lookup, use `Apple Dev Skills:explore-apple-swift-docs` before implementation planning.
- For repo-guidance refresh in this Xcode app repository, use `Apple Dev Skills:sync-xcode-project-guidance`.
- Older references to `apple-xcode-workflow` should be treated as mapping forward to `Apple Dev Skills:xcode-app-project-workflow`.
- Read relevant Apple documentation before making architecture or lifecycle decisions for SwiftUI, `MenuBarExtra`, app scenes, settings windows, app lifecycle, service management, or any SwiftData use in this repository.
- Prefer Xcode-aware tooling and project-safe workflows over manual project-file edits.
- Never edit `.pbxproj` files directly.
- Never edit `SayBar.xcodeproj/project.pbxproj` directly. If a project configuration change is required, make it through Xcode or another project-aware workflow.

### Communication and Escalation

- If correct integration requires widening scope beyond the current app file or this repository, stop and ask Gale to approve the broader pass instead of leaving an in-between architecture behind.
- Before adding a new app-owned controller, queue, storage model, dependency, or service boundary, explain the concrete failure mode it fixes and the simpler extension path considered first.
- When SayBar is represented in `speak-to-user`, keep umbrella docs explicit about whether it is still a sibling repo or already vendored there as a pinned app submodule.

## Commands

### Setup

```sh
open SayBar.xcodeproj
```

Let Xcode resolve Swift package dependencies, then use the `SayBar` scheme for app-facing work.

### Validation

```sh
scripts/repo-maintenance/validate-all.sh
xcodebuild -project SayBar.xcodeproj -scheme SayBar build
xcodebuild -project SayBar.xcodeproj -scheme SayBar test
```

Keep build and test execution serialized. Do not run concurrent Xcode, SwiftPM, or other heavy validation commands on this machine.

### Optional Project Commands

```sh
scripts/repo-maintenance/sync-shared.sh
scripts/repo-maintenance/release.sh --mode standard --version vX.Y.Z
```

Use `scripts/repo-maintenance/sync-shared.sh` for repo-local shared sync tasks and `scripts/repo-maintenance/release.sh` for tagged releases. Keep `scripts/repo-maintenance/config/profile.env` on the `xcode-app` profile for this native Apple app repo.

## Review and Delivery

### Review Expectations

- For Xcode app changes, prefer build-and-run validation through the project scheme, plus any relevant unit or UI tests.
- For docs-only changes, keep edits bounded and preserve intentional document structure.
- For architecture or workflow changes, update nearby maintainer docs, README guidance, roadmap notes, or AGENTS guidance when the durable repo contract changes.
- For release-surface changes, verify the repo-maintenance entrypoints and keep CI as a thin wrapper around local scripts.

### Definition of Done

- The standalone SayBar repo remains the source of truth for app development, tags, and releases.
- The app still hosts and presents `SpeakSwiftlyServer` behavior without re-implementing server or MCP responsibilities.
- Menu bar status remains clear enough for Gale to understand whether services are stopped, starting, ready, degraded, or broken with minimal interaction.
- Settings and menu bar surfaces stay intentionally distinct: quick actions and immediate status in the menu bar, deeper configuration and diagnostics in Settings.
- Validation commands that were relevant to the change have either passed or are reported with exact blockers.

## Safety Boundaries

### Never Do

- Never do feature work, release work, submodule add work, submodule update work, or umbrella-doc edits directly inside the base `../speak-to-user` checkout.
- Never edit `SayBar.xcodeproj/project.pbxproj` directly.
- Never run concurrent Xcode, SwiftPM, or other heavy validation commands.
- Never mirror sibling-library state locally unless there is a concrete app-level reason.
- Never leave transitional shims or duplicate codepaths behind unless Gale explicitly approves that compromise.

### Ask Before

- Ask before widening a SayBar change into `../speak-to-user`, `../SpeakSwiftlyServer`, or `../SpeakSwiftlyMCP`.
- Ask before beginning UI automation, UI test runs, browser automation, screenshot flows, or other focus-stealing interactive validation that may take over Gale's active desktop session.
- Ask before introducing a new controller, coordinator, storage model, helper service, or dependency that changes SayBar's architecture.
- Ask before adopting `SpeakSwiftlyServer` standalone-install helper paths; the current product baseline is embedded-runtime-first.

## Local Overrides

There are no deeper repo-local `AGENTS.md` files in this repository right now. If a future subdirectory adds one, that closer guidance refines this root file for work inside that subtree.

## Monorepo and Submodule Workflow

- Treat the local `../speak-to-user` checkout as a clean protected base checkout only. It must stay on `main`, and it must stay clean.
- For any `speak-to-user` change related to SayBar, create a new branch in a new `git worktree` and do the monorepo work there.
- When the monorepo adopts or updates SayBar, prefer bumping the submodule pointer to a tagged SayBar release rather than an arbitrary branch tip.
- Land monorepo SayBar submodule bumps and related umbrella-doc updates through a pull request against the monorepo instead of pushing those pointer changes directly to monorepo `main`.
- Keep SayBar-specific build, run, and app implementation guidance here in the standalone repo. Keep umbrella docs in `speak-to-user` focused on workspace shape, pinned submodules, and integration boundaries.

## Apple / Xcode Project Workflow

- Use `xcode-build-run-workflow` for normal Xcode build, run, diagnostics, preview, file-membership, and guarded mutation work inside this existing project.
- Use `xcode-testing-workflow` when the task is primarily about Swift Testing, XCTest, XCUITest, `.xctestplan`, flaky tests, retries, or test diagnosis.
- Use `apple-ui-accessibility-workflow` when the task is primarily about SwiftUI accessibility semantics, Apple UI accessibility review, accessibility tree shaping, or UIKit/AppKit accessibility bridge behavior.
- Use `sync-xcode-project-guidance` when the repo guidance for this project drifts and needs to be refreshed or merged forward.
- Re-run `sync-xcode-project-guidance` after substantial Xcode-workflow or plugin updates so local guidance stays aligned.
- Read relevant Apple documentation before proposing or making Xcode, SwiftUI, lifecycle, architecture, or build-configuration changes.
- Prefer Dash or local Apple docs first, then official Apple docs when local docs are insufficient.
- Prefer the simplest correct Swift that is easiest to read and reason about.
- Prefer synthesized and framework-provided behavior over extra wrappers and boilerplate.
- Keep data flow straight and dependency direction unidirectional.
- Treat the `.xcworkspace` or `.xcodeproj` as the source of truth for app integration, schemes, and build settings.
- Prefer Xcode-aware tooling or `xcodebuild` over ad hoc filesystem assumptions when project structure or target membership is involved.
- Prefer Swift Testing for modern unit-style tests, keep XCTest where Apple tooling or dependencies still require it, and use XCUITest with explicit element wait APIs instead of fixed sleeps.
- Keep `.xctestplan` files versioned when the project depends on repeatable test-plan configurations, and inspect or run them explicitly with `xcodebuild -showTestPlans` and `xcodebuild -testPlan ...`.
- Treat accessibility semantics and Apple UI accessibility review as a separate concern from UI automation; use `apple-ui-accessibility-workflow` for the semantic side and `xcode-testing-workflow` for runtime verification and XCUITest follow-through.
- When scripts add files on disk, verify project membership, target membership, build phases, and resource inclusion afterward; files existing in the directory tree alone are not enough.
- Validate both Debug and Release paths when behavior can diverge, and treat tagged releases as a cue to build and verify Release artifacts in addition to the everyday Debug flow.
- Validate Xcode-project changes with explicit `xcodebuild` commands when build or test integrity matters.

## Menu Bar App Expectations

- Optimize for a lightweight, always-available macOS menu bar experience.
- Prefer status clarity over decorative UI.
- Keep settings and menu bar surfaces intentionally distinct.
- When adding background work, ensure app lifecycle behavior is explicit and easy to reason about across launch, relaunch, and quit.

## Integration Guidance

- When wiring `../SpeakSwiftlyServer` or `../SpeakSwiftlyMCP`, document the integration path in `README.md` and keep the boundary honest in code.
- Prefer one clear integration path over transitional shims or duplicate codepaths.
