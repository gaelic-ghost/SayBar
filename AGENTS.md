# SayBar Agent Notes

## Project shape

- SayBar is a native macOS `MenuBarExtra` app built in Xcode.
- Treat the standalone `SayBar` repository as the source of truth for app development, tags, and releases.
- Treat `../speak-to-user/apps/SayBar` as the monorepo integration submodule copy once the umbrella workspace adopts it, not the primary development home.
- The intended role of this repository is to provide the app shell, menu bar UI, settings UI, and macOS-facing service control surface for `SpeakSwiftlyServer`
- Treat those sibling repositories as the primary homes for server and MCP behavior. SayBar should host, supervise, configure, and present them, not casually re-implement their responsibilities.

## Monorepo and submodule workflow

- Treat the local `../speak-to-user` checkout as a clean protected base checkout only. It must stay on `main`, and it must stay clean.
- Never do feature work, release work, submodule add work, submodule update work, or umbrella-doc edits directly inside the base `../speak-to-user` checkout.
- For any `speak-to-user` change related to SayBar, create a new branch in a new `git worktree` and do the monorepo work there.
- When the monorepo adopts or updates SayBar, prefer bumping the submodule pointer to a tagged SayBar release rather than an arbitrary branch tip.
- Land monorepo SayBar submodule bumps and related umbrella-doc updates through a pull request against the monorepo instead of pushing those pointer changes directly to monorepo `main`.
- Keep SayBar-specific build, run, and app implementation guidance here in the standalone repo. Keep umbrella docs in `speak-to-user` focused on workspace shape, pinned submodules, and integration boundaries.

## Apple and Xcode workflow

- Prefer the repo-local Apple Dev Skills plugin workflow when it is installed here.
- For active Xcode execution work, use `Apple Dev Skills:xcode-app-project-workflow` as the top-level entry point.
- For Apple and Swift documentation lookup, use `Apple Dev Skills:explore-apple-swift-docs` before implementation planning.
- For repo-guidance refresh in this Xcode app repository, use `Apple Dev Skills:sync-xcode-project-guidance`.
- Older references to `apple-xcode-workflow` should be treated as mapping forward to `Apple Dev Skills:xcode-app-project-workflow`.
- Read relevant Apple documentation before making architecture or lifecycle decisions for SwiftUI, `MenuBarExtra`, app scenes, SwiftData, settings windows, app lifecycle, or service management.
- Prefer Xcode-aware tooling and project-safe workflows over manual project-file edits.
- Never edit `SayBar.xcodeproj/project.pbxproj` directly. If a project configuration change is required, make it through Xcode or another project-aware workflow.

## Swift and macOS guidance

- Keep SwiftUI structure simple, top-down, and easy to reason about.
- Prefer small focused views and straightforward app state over extra coordinators, managers, wrappers, or duplicate model layers.
- New layers and dependencies are risky here unless they clearly remove complexity, so treat any new abstraction with strong caution and justify it before and after adding it.
- Keep dependency injection unidirectional. UI should depend on stable app-facing interfaces, and app-level integration should depend on the sibling libraries rather than the other way around.
- Preserve clear ownership boundaries between menu bar UI, settings UI, persisted app state, and hosted service behavior.
- Use SwiftData only for state that genuinely belongs to the app. Do not mirror sibling-library state locally unless there is a concrete app-level reason.
- Every operator-facing error, warning, and log string must be descriptive, readable, and specific about what broke, where it broke, and at least one likely cause.

## Menu bar app expectations

- Optimize for a lightweight, always-available macOS menu bar experience.
- Prefer status clarity over decorative UI. Gale should be able to understand whether services are stopped, starting, ready, degraded, or broken with minimal interaction.
- Keep settings and menu bar surfaces intentionally distinct: quick actions and immediate status in the menu bar, deeper configuration and diagnostics in Settings.
- When adding background work, ensure app lifecycle behavior is explicit and easy to reason about across launch, relaunch, and quit.

## Integration guidance

- When wiring `../SpeakSwiftlyServer` or `../SpeakSwiftlyMCP`, document the integration path in `README.md` and keep the boundary honest in code.
- Prefer one clear integration path over transitional shims or duplicate codepaths.
- If correct integration requires widening scope beyond the current app file or current repository, stop and ask Gale to approve the broader pass instead of leaving an in-between architecture behind.
- When SayBar is represented in `speak-to-user`, keep the umbrella docs explicit about whether it is still a sibling repo or already vendored there as a pinned app submodule.

## Verification

- For Xcode app changes, prefer build-and-run validation through the project scheme, plus any relevant unit or UI tests.
- Keep build and test execution serialized. Do not run concurrent Xcode, SwiftPM, or other heavy validation commands on this machine.
- When changing docs, keep edits bounded and preserve intentional document structure.
