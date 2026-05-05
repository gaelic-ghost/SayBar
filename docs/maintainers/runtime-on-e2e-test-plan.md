# Runtime-On E2E Test Plan

## Purpose

This note sketches an optional runtime-on E2E lane for SayBar. The goal is to validate the full Debug app path with real audio: launch SayBar with embedded autostart enabled, submit one or two short speech requests through the menu UI, and confirm the app can drive the embedded `SpeakSwiftlyServer` runtime end to end.

This lane is intentionally separate from the default `SayBar` test plan. It is allowed to play audio, use real models, take longer, and coordinate with the developer's existing LaunchAgent-backed localhost TTS service.

## Safety Contract

Runtime-on E2E tests must not run from CI, `scripts/repo-maintenance/validate-all.sh`, or the default `SayBar.xctestplan`.

They should require explicit local opt-in, for example:

- `SAYBAR_RUNTIME_E2E=1`
- `SAYBAR_RUNTIME_E2E_ALLOW_AUDIO=1`
- `SAYBAR_RUNTIME_E2E_MCP_URL=http://127.0.0.1:7337/mcp`

The test runner must treat the LaunchAgent-backed localhost TTS service as a live local service. Before launching SayBar, it should call the live service's MCP `unload_models` tool and wait until `speak-swiftly://overview` reports resident models unloaded or an equivalent idle state. After the tests finish, including failure or interruption paths, it must call MCP `reload_models` on that same service and wait for the service to report a healthy model-loaded or ready state.

If preflight cannot reach the live service, cannot unload models, or cannot guarantee the reload cleanup hook will run, the runtime-on suite should fail before launching SayBar.

## Proposed Shape

Keep the first implementation outside the default UI target until the behavior is proven:

- add a separate opt-in test plan, such as `SayBarRuntimeE2E.xctestplan`
- include only the runtime-on E2E test case in that plan
- run the app without `--saybar-disable-autostart`
- use a short timeout-tolerant helper for the live service MCP calls
- use short audible strings that identify the lane, such as `SayBar debug E2E one` and `SayBar debug E2E two`
- submit through the same menu path users exercise, likely by setting the pasteboard text and clicking the playback or clipboard speech control
- observe app-level completion through accessible status text, retained request state, or a request resource, rather than relying only on human hearing

The lane should avoid changing persistent user settings unless a test explicitly restores them. It should also avoid clearing existing queues unless Gale explicitly chooses that behavior for the runtime-on lane.

## Open Design Questions

- Should the suite coordinate with the live localhost service over MCP only, or should it use HTTP for health checks and MCP only for `unload_models` and `reload_models`?
- Should SayBar expose a runtime-on test launch argument for shorter deterministic text and profile choices, or should the suite interact only through ordinary menu UI and pasteboard state?
- Should the suite assert request completion through SayBar's embedded runtime state, the app UI, or both?
- Should the suite serialize itself with a local lock file so it cannot overlap with another local TTS or SayBar validation run?
- Which voice profile should be used for the audible checks, and should the suite fail if that profile is unavailable?

## Initial Recommendation

Start with one manually run XCUITest method in a separate test plan:

1. Preflight the live LaunchAgent service at `SAYBAR_RUNTIME_E2E_MCP_URL`.
2. Call MCP `unload_models` on the live service.
3. Launch SayBar in Debug with embedded autostart enabled.
4. Wait for the menu status to indicate the embedded runtime is ready or loaded.
5. Queue one short clipboard speech request through the menu control.
6. Wait for request completion or a clear app-level ready state.
7. Terminate SayBar.
8. Always call MCP `reload_models` on the live LaunchAgent service.

Only add a second audible request after the first request proves stable. The second request should exercise the queue path, not a different architecture path.
