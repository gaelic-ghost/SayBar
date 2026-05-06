//
//  SayBarRuntimeE2ETests.swift
//  SayBarUITests
//
//  Created by Gale Williams on 5/6/26.
//

import AppKit
import XCTest

@MainActor
final class SayBarRuntimeE2ETests: XCTestCase {
    private let launchTimeout: TimeInterval = 10
    private let menuTimeout: TimeInterval = 10
    private let runtimeReadyTimeout: TimeInterval = 180
    private let requestCompletionTimeout: TimeInterval = 240
    private let embeddedHTTP = RuntimeE2EHTTPClient(baseURL: URL(string: "http://127.0.0.1:7339")!)
    private let embeddedMCPURL = URL(string: "http://127.0.0.1:7339/mcp")!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRuntimeOnSpeechRequestsCoverClipboardHTTPAndMCP() async throws {
        let config = try RuntimeE2EConfiguration.fromEnvironment()
        let liveEndpoint = try RuntimeE2EMCPEndpoint(mcpURL: config.liveServiceMCPURL)
        let liveHTTP = RuntimeE2EHTTPClient(baseURL: liveEndpoint.baseURL)
        let liveMCP = try await RuntimeE2EMCPClient.connect(mcpURL: config.liveServiceMCPURL)

        var didUnloadLiveModels = false
        let app = makeRuntimeApp()

        do {
            try await assertLiveServiceHealthy(http: liveHTTP, mcp: liveMCP)
            _ = try await liveMCP.callTool(name: "unload_models")
            didUnloadLiveModels = true
            try await waitForModelsUnloaded(http: liveHTTP, mcp: liveMCP)

            try launchAndWait(app)
            try openMenuExtra(app)
            try await waitForEmbeddedRuntimeReady()
            try await assertMenuShowsIdleQueue(app)

            let beforeClipboardRequests = try await embeddedRequestIDs()
            try submitClipboardRequest(
                app,
                text: "SayBar runtime end-to-end clipboard check. This should play from the menu bar clipboard route."
            )
            try await waitForNewCompletedRequest(after: beforeClipboardRequests)
            try await waitForEmbeddedRuntimeIdle()
            try await assertMenuShowsIdleQueue(app)

            let httpRequestID = try await submitHTTPSpeech(
                text: "SayBar runtime end-to-end HTTP check. This should play from the embedded HTTP surface."
            )
            try await waitForCompletedHTTPRequest(httpRequestID)
            try await waitForEmbeddedRuntimeIdle()
            try await assertMenuShowsIdleQueue(app)

            let mcp = try await RuntimeE2EMCPClient.connect(mcpURL: embeddedMCPURL)
            try await assertEmbeddedMCPSurfaceReady(mcp)
            let mcpRequestID = try await submitMCPSpeech(
                using: mcp,
                text: "SayBar runtime end-to-end MCP check. This should play from the embedded MCP surface."
            )
            try await waitForCompletedMCPRequest(mcpRequestID, using: mcp)
            try await waitForEmbeddedRuntimeIdle()
            try await assertMenuShowsIdleQueue(app)

            app.terminate()
            _ = app.wait(for: .notRunning, timeout: 5)

            try await reloadLiveModelsIfNeeded(
                didUnloadLiveModels: didUnloadLiveModels,
                http: liveHTTP,
                mcp: liveMCP
            )
        } catch {
            if app.state != .notRunning {
                app.terminate()
                _ = app.wait(for: .notRunning, timeout: 5)
            }
            try await reloadLiveModelsIfNeeded(
                didUnloadLiveModels: didUnloadLiveModels,
                http: liveHTTP,
                mcp: liveMCP
            )
            throw error
        }
    }
}

private extension SayBarRuntimeE2ETests {
    func makeRuntimeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPEAKSWIFTLY_PLAYBACK_TRACE"] = "0"
        return app
    }

    func launchAndWait(_ app: XCUIApplication) throws {
        app.launch()
        let launchedInForeground = app.wait(for: .runningForeground, timeout: launchTimeout)
        let launchedInBackground = launchedInForeground ? false : app.wait(for: .runningBackground, timeout: 2)

        try runtimeE2ERequire(
            launchedInForeground || launchedInBackground,
            "SayBar should launch with embedded-runtime autostart enabled for runtime-on E2E testing."
        )
    }

    func openMenuExtra(_ app: XCUIApplication) throws {
        let appMenuExtra = app.descendants(matching: .any)["saybar-menu-bar-extra"]
        if appMenuExtra.waitForExistence(timeout: 2) {
            appMenuExtra.click()
            return
        }

        let systemUIServer = XCUIApplication(bundleIdentifier: "com.apple.systemuiserver")
        let systemMenuExtra = systemUIServer.descendants(matching: .any)["SayBar"]
        try runtimeE2ERequire(
            systemMenuExtra.waitForExistence(timeout: menuTimeout),
            "SayBar should publish a menu bar extra that the runtime-on E2E suite can open by accessibility label."
        )
        systemMenuExtra.click()
    }

    func submitClipboardRequest(_ app: XCUIApplication, text: String) throws {
        NSPasteboard.general.clearContents()
        try runtimeE2ERequire(
            NSPasteboard.general.setString(text, forType: .string),
            "Runtime-on E2E should be able to seed the macOS pasteboard with the clipboard speech request text."
        )

        let button = app.descendants(matching: .any)["saybar-playback-or-clipboard-speech"]
        try runtimeE2ERequire(
            button.waitForExistence(timeout: menuTimeout),
            "SayBar should expose the clipboard speech control before the runtime-on E2E suite clicks it."
        )
        try runtimeE2ERequire(
            button.isHittable,
            "SayBar clipboard speech control should be hittable when the embedded runtime is ready."
        )
        button.click()
    }

    func assertMenuShowsIdleQueue(_ app: XCUIApplication) async throws {
        _ = try await waitUntil(timeout: 20, pollInterval: 0.5) {
            let idleSummary = app.descendants(matching: .any)["Generation: 0 active, 0 queued / 24"]
            return idleSummary.exists ? true : nil
        }
    }
}

private extension SayBarRuntimeE2ETests {
    func assertLiveServiceHealthy(http: RuntimeE2EHTTPClient, mcp: RuntimeE2EMCPClient) async throws {
        let readiness = try await http.decoded(RuntimeE2EReadinessSnapshot.self, path: "/readyz")
        try runtimeE2ERequire(
            readiness.status == "ready",
            "LaunchAgent-backed localhost service should report ready before runtime-on E2E unloads resident models. Actual status: \(readiness.status)."
        )

        let overview = try await http.decoded(RuntimeE2EOverviewSnapshot.self, path: "/overview")
        try runtimeE2ERequire(
            overview.transportState(named: "mcp") == "listening",
            "LaunchAgent-backed localhost service should report MCP listening before runtime-on E2E starts. Actual state: \(overview.transportState(named: "mcp") ?? "missing")."
        )

        let mcpOverview = try await mcp.readResourceJSON(uri: "speak-swiftly://overview")
        try runtimeE2ERequire(
            mcpOverview["worker_mode"] as? String == "ready",
            "LaunchAgent-backed localhost service MCP overview should report worker_mode=ready before runtime-on E2E starts."
        )
    }

    func waitForModelsUnloaded(http: RuntimeE2EHTTPClient, mcp: RuntimeE2EMCPClient) async throws {
        _ = try await waitUntil(timeout: runtimeReadyTimeout, pollInterval: 1) {
            let readiness = try await http.decoded(
                RuntimeE2EReadinessSnapshot.self,
                path: "/readyz",
                acceptedStatusCodes: [200, 503]
            )
            let mcpOverview = try await mcp.readResourceJSON(uri: "speak-swiftly://overview")
            let mcpWorkerStage = mcpOverview["worker_stage"] as? String
            return readiness.workerStage == "resident_models_unloaded" && mcpWorkerStage == "resident_models_unloaded" ? true : nil
        }
    }

    func reloadLiveModelsIfNeeded(
        didUnloadLiveModels: Bool,
        http: RuntimeE2EHTTPClient,
        mcp: RuntimeE2EMCPClient
    ) async throws {
        guard didUnloadLiveModels else { return }

        _ = try await mcp.callTool(name: "reload_models")
        _ = try await waitUntil(timeout: runtimeReadyTimeout, pollInterval: 1) {
            let readiness = try await http.decoded(
                RuntimeE2EReadinessSnapshot.self,
                path: "/readyz",
                acceptedStatusCodes: [200, 503]
            )
            let mcpOverview = try await mcp.readResourceJSON(uri: "speak-swiftly://overview")
            let mcpWorkerMode = mcpOverview["worker_mode"] as? String
            let mcpWorkerStage = mcpOverview["worker_stage"] as? String
            let httpReady = readiness.workerReady && readiness.workerMode == "ready"
            let mcpReady = mcpWorkerMode == "ready" && mcpWorkerStage != "resident_models_unloaded"
            return httpReady && mcpReady ? true : nil
        }
    }
}

private extension SayBarRuntimeE2ETests {
    func waitForEmbeddedRuntimeReady() async throws {
        _ = try await waitUntil(timeout: runtimeReadyTimeout, pollInterval: 1) {
            let readiness = try await self.embeddedHTTP.decoded(RuntimeE2EReadinessSnapshot.self, path: "/readyz")
            let overview = try await self.embeddedHTTP.decoded(RuntimeE2EOverviewSnapshot.self, path: "/overview")
            let ready = readiness.workerReady
                && readiness.workerMode == "ready"
                && overview.serverMode == "ready"
                && overview.transportState(named: "mcp") == "listening"
            return ready ? true : nil
        }
    }

    func waitForEmbeddedRuntimeIdle() async throws {
        _ = try await waitUntil(timeout: requestCompletionTimeout, pollInterval: 1) {
            let overview = try await self.embeddedHTTP.decoded(RuntimeE2EOverviewSnapshot.self, path: "/overview")
            return overview.hasNoActiveSpeechWork ? true : nil
        }
    }

    func assertEmbeddedMCPSurfaceReady(_ mcp: RuntimeE2EMCPClient) async throws {
        let overview = try await mcp.readResourceJSON(uri: "speak-swiftly://overview")
        try runtimeE2ERequire(
            overview["server_mode"] as? String == "ready",
            "SayBar embedded MCP overview should report server_mode=ready before the MCP audible request."
        )
        try runtimeE2ERequire(
            overview["worker_mode"] as? String == "ready",
            "SayBar embedded MCP overview should report worker_mode=ready before the MCP audible request."
        )
    }
}

private extension SayBarRuntimeE2ETests {
    func embeddedRequestIDs() async throws -> Set<String> {
        let list = try await embeddedHTTP.decoded(RuntimeE2ERequestList.self, path: "/requests")
        return Set(list.requests.map(\.requestID))
    }

    func waitForNewCompletedRequest(after existingRequestIDs: Set<String>) async throws {
        let job = try await waitUntil(timeout: requestCompletionTimeout, pollInterval: 1) {
            let list = try await self.embeddedHTTP.decoded(RuntimeE2ERequestList.self, path: "/requests")
            return list.requests.first { job in
                !existingRequestIDs.contains(job.requestID) && job.terminalEvent != nil
            }
        }
        try assertCompleted(job)
    }

    func submitHTTPSpeech(text: String) async throws -> String {
        let response = try await embeddedHTTP.request(
            path: "/speech/live",
            method: "POST",
            jsonBody: [
                "text": text,
                "request_context": [
                    "source": "HTTP via SayBar Runtime E2E",
                    "attributes": [
                        "saybar.e2e.surface": "http",
                    ],
                ],
            ]
        )
        try runtimeE2ERequire(
            response.statusCode == 202,
            "SayBar embedded HTTP speech request should return HTTP 202. Actual status: \(response.statusCode). Body: \(response.text)"
        )
        return try runtimeE2EDecode(RuntimeE2EAcceptedRequest.self, from: response.data).requestID
    }

    func waitForCompletedHTTPRequest(_ requestID: String) async throws {
        let job: RuntimeE2EJobSnapshot = try await waitUntil(timeout: requestCompletionTimeout, pollInterval: 1) {
            let response = try await self.embeddedHTTP.request(path: "/requests/\(requestID)", method: "GET")
            guard response.statusCode == 200 else { return nil }
            let job = try runtimeE2EDecode(RuntimeE2EJobSnapshot.self, from: response.data)
            return job.terminalEvent == nil ? nil : job
        }
        try assertCompleted(job)
    }

    func submitMCPSpeech(using mcp: RuntimeE2EMCPClient, text: String) async throws -> String {
        let payload = try await mcp.callTool(
            name: "generate_speech",
            arguments: [
                "text": text,
                "request_context": [
                    "source": "MCP via SayBar Runtime E2E",
                    "attributes": [
                        "saybar.e2e.surface": "mcp",
                    ],
                ],
            ]
        )
        return try runtimeE2EString("request_id", in: payload)
    }

    func waitForCompletedMCPRequest(_ requestID: String, using mcp: RuntimeE2EMCPClient) async throws {
        let job = try await waitUntil(timeout: requestCompletionTimeout, pollInterval: 1) {
            let payload = try await mcp.readResourceJSON(uri: "speak-swiftly://requests/\(requestID)")
            let data = try JSONSerialization.data(withJSONObject: payload)
            let job = try runtimeE2EDecode(RuntimeE2EJobSnapshot.self, from: data)
            return job.terminalEvent == nil ? nil : job
        }
        try assertCompleted(job)
    }

    func assertCompleted(_ job: RuntimeE2EJobSnapshot) throws {
        let latest = job.history.last
        try runtimeE2ERequire(
            job.completedSuccessfully,
            """
            Runtime-on E2E request '\(job.requestID)' did not complete successfully.
            status: \(job.status)
            terminal_ok: \(String(describing: job.terminalEvent?.ok))
            terminal_code: \(job.terminalEvent?.code ?? "nil")
            terminal_message: \(job.terminalEvent?.message ?? "nil")
            latest_event: \(latest?.event ?? "nil")
            latest_stage: \(latest?.stage ?? "nil")
            """
        )

        try runtimeE2ERequire(
            job.history.contains { $0.event == "started" && $0.op == "generate_speech" },
            "Runtime-on E2E request '\(job.requestID)' should record a generate_speech start event."
        )
        try runtimeE2ERequire(
            job.history.contains { $0.event == "progress" && $0.stage == "playback_finished" },
            "Runtime-on E2E request '\(job.requestID)' should record playback_finished before the suite considers it complete."
        )
    }
}

private struct RuntimeE2EConfiguration {
    let liveServiceMCPURL: URL

    static func fromEnvironment() throws -> RuntimeE2EConfiguration {
        let environment = ProcessInfo.processInfo.environment
        guard environment["SAYBAR_RUNTIME_E2E"] == "1" else {
            throw XCTSkip("Runtime-on E2E is opt-in. Set SAYBAR_RUNTIME_E2E=1 to run audible SayBar runtime tests.")
        }
        guard environment["SAYBAR_RUNTIME_E2E_ALLOW_AUDIO"] == "1" else {
            throw XCTSkip("Runtime-on E2E plays audible speech. Set SAYBAR_RUNTIME_E2E_ALLOW_AUDIO=1 to allow playback.")
        }
        guard let rawMCPURL = environment["SAYBAR_RUNTIME_E2E_MCP_URL"], !rawMCPURL.isEmpty else {
            throw XCTSkip("Runtime-on E2E needs SAYBAR_RUNTIME_E2E_MCP_URL for the LaunchAgent-backed localhost TTS service.")
        }
        guard let liveServiceMCPURL = URL(string: rawMCPURL) else {
            throw RuntimeE2EError("Runtime-on E2E MCP URL '\(rawMCPURL)' is not a valid URL.")
        }

        return RuntimeE2EConfiguration(liveServiceMCPURL: liveServiceMCPURL)
    }
}

private func waitUntil<T>(
    timeout: TimeInterval,
    pollInterval: TimeInterval,
    condition: @escaping () async throws -> T?
) async throws -> T {
    let deadline = Date().addingTimeInterval(timeout)
    var lastError: Error?

    while Date() < deadline {
        do {
            if let value = try await condition() {
                return value
            }
        } catch {
            lastError = error
        }

        try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }

    if let lastError {
        throw RuntimeE2EError("Runtime E2E timed out after \(timeout) seconds. Most recent polling error: \(lastError)")
    }
    throw RuntimeE2EError("Runtime E2E timed out after \(timeout) seconds before the expected condition became true.")
}

private func runtimeE2ERequire(_ condition: Bool, _ message: String) throws {
    guard condition else {
        throw RuntimeE2EError(message)
    }
}
