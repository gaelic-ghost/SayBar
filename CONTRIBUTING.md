# Contributing to SayBar

Use this guide when preparing changes so the project stays understandable, runnable, and reviewable for the next contributor.

## Table of Contents

- [Overview](#overview)
- [Contribution Workflow](#contribution-workflow)
- [Local Setup](#local-setup)
- [Development Expectations](#development-expectations)
- [Pull Request Expectations](#pull-request-expectations)
- [Communication](#communication)
- [License and Contribution Terms](#license-and-contribution-terms)

## Overview

### Who This Guide Is For

Use this guide for changes to the standalone SayBar macOS app repository, including app code, maintainer docs, Xcode workflow guidance, repo-maintenance scripts, and release surfaces.

### Before You Start

Read `README.md`, `AGENTS.md`, and the maintainer docs under `docs/maintainers/` before changing app architecture or release workflow. Treat the standalone SayBar repo as the app source of truth, and ask before widening work into `../speak-to-user`, `../SpeakSwiftlyServer`, or `../SpeakSwiftlyMCP`.

## Contribution Workflow

### Choosing Work

Start from the current roadmap, maintainer docs, or an issue/PR discussion. For changes that touch app ownership, service control, Xcode project behavior, or release workflow, confirm the intended scope before introducing a new controller, storage model, helper service, dependency, or wider repository change.

### Making Changes

Work on a feature branch. Keep SwiftUI structure simple and direct, preserve the direct app-owned `EmbeddedServer` baseline, and avoid direct `.pbxproj` edits. Keep docs changes bounded and preserve existing document structure unless the task explicitly calls for a structural rewrite.

### Asking For Review

A change is ready for review when the app still builds through the `SayBar` scheme, relevant tests or docs checks have run, and any architecture or workflow contract change is reflected in nearby maintainer docs.

## Local Setup

### Runtime Config

Open `SayBar.xcodeproj` in Xcode, select the `SayBar` scheme, and let Xcode resolve package dependencies. The app uses the Xcode-resolved `SpeakSwiftlyServer` package as its embedded runtime dependency.

### Runtime Behavior

Normal app runs start the embedded runtime from inside SayBar. UI-test and shell-focused launches can pass `--saybar-disable-autostart` to validate the app shell without starting the full embedded runtime.

## Development Expectations

### Naming Conventions

Use `EmbeddedServer` for the app-owned runtime model and `SpeakSwiftlyServer` for the package dependency. Use "embedded runtime" for the current product baseline, and reserve "standalone server" or "LaunchAgent-backed server" for future app-managed install work.

### Accessibility Expectations

Contributors must keep UI changes aligned with the current accessibility and UI-automation notes in [`docs/maintainers/accessibility-and-ui-automation-notes.md`](docs/maintainers/accessibility-and-ui-automation-notes.md).

If a change affects UI semantics, input behavior, focus flow, labels, announcements, motion, contrast, zoom behavior, content structure, or assistive-technology compatibility, verify the affected surface against the documented accessibility standards before asking for review.

If a change introduces a new accessibility limitation, exception, or remediation plan, update the maintainer accessibility notes in the same pass unless maintainers have explicitly agreed on a different tracking path.

### Verification

Run relevant checks serially. For app work, prefer:

```sh
scripts/repo-maintenance/validate-all.sh
xcodebuild -project SayBar.xcodeproj -scheme SayBar build
xcodebuild -project SayBar.xcodeproj -scheme SayBar test
```

## Pull Request Expectations

A good pull request explains the user-visible or maintainer-visible change, names any dependency or workflow alignment performed, and lists the validation commands that passed or the exact blocker that prevented them.

## Communication

Surface uncertainty early when a change may widen beyond this repo, alter the direct `EmbeddedServer` baseline, or require Xcode project configuration work. Keep review comments short, concrete, and grounded in the code or docs being changed.

## License and Contribution Terms

Contributions are provided under the project license in `LICENSE`.
