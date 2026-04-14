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
- Replace placeholder UI with real app-owned state and service hooks.
- Document the app's development and integration boundaries clearly.

### Tickets

- [x] Keep a standalone Xcode app target with `SayBar`, `SayBarTests`, and `SayBarUITests`.
- [x] Wire the project to the `SpeakSwiftlyServer` package product used by the app shell.
- [x] Keep repo-facing docs (`README.md`, `ROADMAP.md`, `AGENTS.md`) tracked in the project.
- [x] Replace scaffold text in the menu bar and settings views with app-owned UI structure.
- [x] Introduce the first real service supervision path from the app shell into sibling services.

### Exit criteria

- [x] The app surfaces real status instead of placeholder text.
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
- Keep the embedded-session operator surface grounded while deciding whether SayBar should remain embedded-first or evolve toward an optional controller that can attach to an external `SpeakSwiftlyServer`.

### Tickets

- [x] Keep app persistence narrow and app-owned instead of mirroring sibling-service runtime state locally.
- [x] Host the embedded `SpeakSwiftlyServer` session through an app-owned controller.
- [x] Surface runtime, playback, transport, and diagnostics sections in Settings.
- [x] Build settings sections for configuration that genuinely belongs to the macOS app.
- [x] Add diagnostics surfaces for logs, startup failures, and likely-cause messaging.
- [ ] Choose and document the long-term controller model for embedded, attached, and launch-agent-backed service ownership.
- [ ] Verify launch, relaunch, and quit behavior for background work.

### Exit criteria

- [x] Settings owns deeper configuration and diagnostics cleanly.
- [x] Operator-facing failures are specific, readable, and actionable.
- [x] The current embedded-session operator surface is implemented and documented.
- [ ] The app's process-ownership model is explicit for embedded, attached, or launch-agent-backed service control.
- [ ] App lifecycle behavior is explicit across launch and shutdown.

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
