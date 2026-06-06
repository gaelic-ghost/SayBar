# XcodeGen Project Contract

This note records the migration from an Xcode-authored project file to an XcodeGen-backed project specification with external Xcode build settings configuration files.

## Current State

- `project.yml` is the source of truth for target definitions, schemes, package references, and file membership.
- `Config/SayBar.xcconfig` is the source of truth for shared build settings.
- `SayBar.xcodeproj` is tracked generated output so Xcode opens normally.
- `SayBar.xctestplan` and `SayBarRuntimeE2E.xctestplan` are checked in and should stay checked in.
- The active app-facing scheme is `SayBar`.
- The app target depends on the `SpeakSwiftlyServer` package product through the XcodeGen package declaration.
- The current deployment target is macOS `15.6`.
- The current Swift language mode is Swift `6.0`.

## Desired Source Of Truth

Use the deliberate two-file split:

- `project.yml` owns project shape: targets, schemes, source membership, package references, test-plan wiring, build phases, and generated project options.
- `Config/SayBar.xcconfig` owns shared build settings values that should be readable and reviewable outside the generated project file.

This is a durable building-block change. It removes the failure mode where routine build-setting or file-membership edits become hard-to-review `.pbxproj` changes, and it gives future target or settings edits one plain-text entry point.

## Documentation Anchors

- Apple documents `.xcconfig` files as plain-text build configuration files that Xcode layers with project and target settings: [Adding a build configuration file to your project](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project/).
- Apple documents Xcode project creation and target configuration as the normal starting point for app projects: [Creating an Xcode project for an app](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app).
- XcodeGen documents YAML or JSON project specs, target definitions, build settings, and per-configuration `configFiles`: [XcodeGen Project Spec](https://yonaskolb.github.io/XcodeGen/Docs/ProjectSpec.html).
- XcodeGen documents build-setting precedence across target settings, target xcconfig files, project settings, project xcconfig files, and SDK defaults: [XcodeGen Usage](https://yonaskolb.github.io/XcodeGen/Docs/Usage.html).

## Completed Migration Slices

### 1. Capture The Existing Project Contract

- Record the current project inventory with `xcodebuild -list -project SayBar.xcodeproj`.
- Record available test plans with `xcodebuild -showTestPlans -project SayBar.xcodeproj -scheme SayBar`.
- Record effective app target build settings with `xcodebuild -showBuildSettings -project SayBar.xcodeproj -scheme SayBar`.
- Confirm the package pin in `SayBar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- Decide whether the currently staged empty `SayBarAppDelegate.swift` should be removed, completed, or intentionally added to the app target before generation work begins.

### 2. Add A Shadow XcodeGen Spec

- Add `project.yml` as the project-shape source of truth.
- Model the existing targets:
  - `SayBar`
  - `SayBarTests`
  - `SayBarUITests`
- Model the `SpeakSwiftlyServer` package dependency from the real GitHub URL and pinned version.
- Model the checked-in test plans and preserve the current `SayBar` scheme behavior.
- Keep generated `Info.plist` behavior unless a separate product decision moves it to checked-in plist files.
- Run `xcodegen generate --spec project.yml` after spec or shared build-setting changes.

### 3. Move Shared Settings Into XCConfig

- Add `Config/SayBar.xcconfig` for shared settings such as:
  - `MACOSX_DEPLOYMENT_TARGET = 15.6`
  - `SWIFT_VERSION = 6.0`
  - `SWIFT_STRICT_CONCURRENCY = complete`
  - `ENABLE_USER_SCRIPT_SANDBOXING = YES`
  - app version and build number settings when they are not better kept in release automation
- Keep per-target bundle identifiers and generated Info.plist keys either in `project.yml` or in target-specific xcconfig files if the shared file becomes crowded.
- Do not put secrets, machine-local paths, or private developer-only values in checked-in xcconfig files.

### 4. Generate And Compare

- Run `xcodegen generate --spec project.yml`.
- Review `project.yml`, `Config/SayBar.xcconfig`, and the generated `SayBar.xcodeproj/project.pbxproj` together.
- Check for accidental loss of:
  - target membership
  - test target host/application relationships
  - package product linkage
  - test-plan references
  - asset catalog inclusion
  - generated Info.plist keys
  - signing and bundle identifier settings
- Keep the generated `.pbxproj` tracked during the transition so Xcode opens normally for contributors without requiring generation as a first step.

### 5. Switch The Repo Contract

- Update `README.md` setup and validation instructions to mention `xcodegen generate`.
- Keep `AGENTS.md` on the existing XcodeGen guidance because it already says to edit the spec and regenerate instead of hand-editing generated `.pbxproj` files.
- Add a repo-maintenance validation script that checks the generated project is in sync with `project.yml`.
- Keep CI using the repo-maintenance entrypoint so generated-project drift is caught by the managed `validate` job.

## Validation Gate

Run these checks after changing `project.yml`, `Config/SayBar.xcconfig`, package versions, or generated project output:

```sh
xcodegen generate --spec project.yml
xcodebuild -list -project SayBar.xcodeproj
xcodebuild -showTestPlans -project SayBar.xcodeproj -scheme SayBar
xcodebuild -project SayBar.xcodeproj -scheme SayBar build
xcodebuild -project SayBar.xcodeproj -scheme SayBar test -testPlan SayBar
scripts/repo-maintenance/validate-all.sh
```

Keep these commands serialized. Do not run Xcode, SwiftPM, XcodeGen regeneration, or repo-maintenance validation concurrently on Gale's machine.

## Open Decisions

- Whether to require XcodeGen through Homebrew, Mint, a repo-local script, or another pinned installation path.
- Whether to keep `SayBar.xcodeproj` tracked permanently or treat it as generated after the repo has enough validation coverage.
- Whether to split xcconfig files by target or configuration after the first shared `Config/SayBar.xcconfig` exists.
- Whether release automation should own `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`, or whether those values should stay in checked-in project settings for now.
