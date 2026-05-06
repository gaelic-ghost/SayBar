# Runtime-On E2E Test Plan

## Purpose

This note sketches an optional runtime-on E2E lane for SayBar. The goal is to validate the full Debug app path with real audio: launch SayBar with embedded autostart enabled, submit short speech requests through the real app and runtime surfaces, and confirm the app can drive the embedded `SpeakSwiftlyServer` runtime end to end.

This lane is intentionally separate from the default `SayBar` test plan. It is allowed to play audio, use real models, take longer, and coordinate with the developer's existing LaunchAgent-backed localhost TTS service.

## Safety Contract

Runtime-on E2E tests must not run from CI, `scripts/repo-maintenance/validate-all.sh`, or the default `SayBar.xctestplan`.

They should require explicit local opt-in, for example:

- `SAYBAR_RUNTIME_E2E=1`
- `SAYBAR_RUNTIME_E2E_ALLOW_AUDIO=1`
- `SAYBAR_RUNTIME_E2E_MCP_URL=http://127.0.0.1:7337/mcp`

The test runner must treat the LaunchAgent-backed localhost TTS service as a live local service. Before launching SayBar, it should call the live service's MCP `unload_models` tool and wait until `speak-swiftly://overview` reports resident models unloaded or an equivalent idle state. After the tests finish, including failure or interruption paths, it must call MCP `reload_models` on that same service and wait for the service to report a healthy model-loaded or ready state.

If preflight cannot reach the live service, cannot unload models, or cannot guarantee the reload cleanup hook will run, the runtime-on suite should fail before launching SayBar.

The runtime-on suite is expected to run sequentially because XCUITest drives one app-under-test through one active desktop session. Do not add an extra local lock file for the first implementation, but do not run this lane at the same time as another SayBar, SpeakSwiftlyServer, or audible audio validation pass.

## Implemented Shape

The first implementation lives outside the default test plan and is only active through explicit runtime-on configuration:

- use `SayBarRuntimeE2E.xctestplan`
- include only `SayBarRuntimeE2ETests` in that plan
- run the app without `--saybar-disable-autostart`
- use a short timeout-tolerant helper for the live service MCP calls
- use short two-sentence audible strings that identify the lane and surface
- submit one request through the clipboard route by setting the pasteboard text and clicking the menu's clipboard speech control
- submit one request through the embedded HTTP speech surface while SayBar is running
- submit one request through the embedded MCP speech surface while SayBar is running
- check both the visible app surface and the embedded runtime state for completion instead of relying only on human hearing
- check both the MCP surface and HTTP health or status surface when coordinating with the live localhost service

Run the lane manually with:

```sh
xcodebuild -project SayBar.xcodeproj -scheme SayBar -testPlan SayBarRuntimeE2E test
```

The lane should avoid changing persistent user settings unless a test explicitly restores them. It should also avoid clearing existing queues unless Gale explicitly chooses that behavior for the runtime-on lane.

## Settled Initial Decisions

- Use a separate opt-in XCUITest plan and keep it outside CI and default validation.
- Use the clipboard route as one request surface because it mirrors a real daily-driver workflow.
- Exercise both embedded runtime transport surfaces, HTTP and MCP, with separate short audible requests so one obvious break in either path is caught quickly.
- Run all three audible checks in one runtime-on suite pass: clipboard UI, embedded HTTP, and embedded MCP.
- Assert completion from both the UI and runtime state.
- Check both MCP and HTTP service surfaces during live-service coordination.
- Keep execution sequential through XCUITest rather than adding a first-pass lock file.

## Open Design Questions

- Should SayBar expose a runtime-on test launch argument for shorter deterministic text and profile choices, or should the suite interact only through ordinary menu UI and pasteboard state?
- Which exact embedded runtime observation should count as request completion: a queue count drop, last request state, playback-idle transition, request resource, or a combination?
- Which voice profile should be used for the audible checks, and should the suite fail if that profile is unavailable?

## Runtime Sequence

The checked-in runtime-on XCUITest method follows this sequence:

1. Preflight the live LaunchAgent service at `SAYBAR_RUNTIME_E2E_MCP_URL`.
2. Check the live service's MCP and HTTP surfaces.
3. Call MCP `unload_models` on the live service.
4. Confirm the live service reports resident models unloaded.
5. Launch SayBar in Debug with embedded autostart enabled.
6. Wait for the menu status and embedded runtime state to indicate the app runtime is ready or loaded.
7. Queue one short two-sentence clipboard speech request through the menu control.
8. Wait for request completion from both visible app state and embedded runtime state.
9. Queue one short two-sentence speech request through the embedded HTTP surface.
10. Wait for request completion from both visible app state and embedded runtime state.
11. Queue one short two-sentence speech request through the embedded MCP surface.
12. Wait for request completion from both visible app state and embedded runtime state.
13. Terminate SayBar.
14. Always call MCP `reload_models` on the live LaunchAgent service.
15. Confirm the live service's MCP and HTTP surfaces return to a healthy model-loaded or ready state.
