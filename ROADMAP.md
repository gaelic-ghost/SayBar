# ROADMAP

## Vision

- Build SayBar into a reliable macOS menu bar control surface for speech service lifecycle, status, diagnostics, and settings without re-implementing server responsibilities inside the app repo.

## Product principles

- [ ] Keep the app lightweight, always-available, and easy to understand at a glance.
- [ ] Keep service ownership boundaries honest between SayBar and its sibling service repositories.
- [ ] Prefer clear status and operator diagnostics over decorative interface work.
- [ ] Preserve release discipline between the standalone app repo and any future monorepo submodule adoption.

## Milestone Progress

- [x] M1. App shell foundation and service-hosting boundaries
- [x] M2. Status-driven menu bar experience
- [ ] M3. Settings, diagnostics, and operator workflow
- [ ] M4. Release and monorepo integration discipline

## M1. App shell foundation and service-hosting boundaries

### Scope

- Stabilize the standalone macOS app shell.
- Replace scaffold UI with real app-owned state and service hooks.
- Document the app's development and integration boundaries clearly.

### Tickets

- [x] Keep a standalone Xcode app target with `SayBar`, `SayBarTests`, and `SayBarUITests`.
- [x] Wire the project to the `SpeakSwiftlyServer` package product used by the app shell.
- [x] Keep repo-facing docs (`README.md`, `ROADMAP.md`, `AGENTS.md`) tracked in the project.
- [x] Replace scaffold text in the menu bar and settings views with app-owned UI structure.
- [x] Introduce the first real service supervision path from the app shell into sibling services.

### Exit criteria

- [x] The app surfaces real status instead of scaffold text.
- [x] The first hosted-service integration path is documented and implemented without duplicate service logic in the app repo.
- [x] The standalone repo docs accurately describe the app's role and current state.

## M2. Status-driven menu bar experience

### Scope

- Build the quick-action and status surface that Gale can rely on from the menu bar.

### Tickets

- [x] Define app-level service states such as stopped, starting, ready, degraded, and broken.
- [x] Present those states clearly in the menu bar UI.
- [x] Add quick actions for the most common operator workflows.
- [x] Add human-friendly error and warning strings for failed or degraded states.

### Exit criteria

- [x] Gale can tell the current service state with minimal interaction.
- [x] The menu bar surface supports the core day-to-day control flow without opening Settings.

## M3. Settings, diagnostics, and operator workflow

### Scope

- Move deeper configuration and diagnostics into the Settings experience.
- Keep the embedded runtime operator surface grounded while hardening the accepted direct-`EmbeddedServer` product model.

### Tickets

- [x] Keep app persistence narrow and app-owned instead of mirroring sibling-service runtime state locally.
- [x] Host the embedded `SpeakSwiftlyServer` runtime through one app-owned `EmbeddedServer` model.
- [x] Surface runtime, playback, transport, and diagnostics sections in Settings.
- [x] Build settings sections for configuration that genuinely belongs to the macOS app.
- [x] Add diagnostics surfaces for logs, startup failures, and likely-cause messaging.
- [x] Choose and document the long-term direct-embedding product baseline for App Store-compatible delivery.
- [ ] Verify launch, relaunch, and quit behavior for background work.

### Exit criteria

- [x] Settings owns deeper configuration and diagnostics cleanly.
- [x] Operator-facing failures are specific, readable, and actionable.
- [x] The current embedded runtime operator surface is implemented and documented.
- [x] The app's product-baseline process-ownership model is explicit.
- [ ] App lifecycle behavior is explicit across launch and shutdown.

### Notes

- The accepted architecture decision is recorded in [docs/maintainers/adr-0001-keep-direct-embeddedserver-baseline.md](docs/maintainers/adr-0001-keep-direct-embeddedserver-baseline.md).
- Launch, terminate, and relaunch behavior is now explicit in app code and covered by launch-only UI tests with embedded autostart disabled. A fuller runtime-on verification pass remains open work.
- Future attached-session or bundled-helper exploration remains a separate product decision, not an implied follow-up to the current roadmap.

## M4. Release and monorepo integration discipline

### Scope

- Keep standalone releases and future `speak-to-user` integration predictable.

### Tickets

- [ ] Tag standalone SayBar releases from this repository.
- [ ] Prefer monorepo adoption through pinned submodule releases instead of arbitrary branch tips.
- [ ] Land monorepo pointer bumps and umbrella-doc updates through pull requests.
- [ ] Keep umbrella docs explicit about whether SayBar is still sibling-hosted or vendored as a submodule.

### Exit criteria

- [ ] Standalone app releases remain the source of truth.
- [ ] Monorepo integration work follows an isolated worktree and PR-based flow.
