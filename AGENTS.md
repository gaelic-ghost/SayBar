# SayBar Agent Notes

## Project shape

- SayBar is a native macOS `MenuBarExtra` app built in Xcode.
- The intended role of this repository is to provide the app shell, menu bar UI, settings UI, and macOS-facing service control surface for the sibling repositories `../SpeakSwiftlyServer` and `../SpeakSwiftlyMCP`.
- Treat those sibling repositories as the primary homes for server and MCP behavior. SayBar should host, supervise, configure, and present them, not casually re-implement their responsibilities.

## Apple and Xcode workflow

- Use the `apple-xcode-workflow` skill first for Xcode-related work.
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

## Verification

- For Xcode app changes, prefer build-and-run validation through the project scheme, plus any relevant unit or UI tests.
- Keep build and test execution serialized. Do not run concurrent Xcode, SwiftPM, or other heavy validation commands on this machine.
- When changing docs, keep edits bounded and preserve intentional document structure.
