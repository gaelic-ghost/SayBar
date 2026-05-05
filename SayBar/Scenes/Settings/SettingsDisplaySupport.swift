//
//  SettingsDisplaySupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

enum SettingsDisplaySupport {
    nonisolated static func enabledStatus(_ isEnabled: Bool) -> String {
        isEnabled ? "Enabled" : "Disabled"
    }

    nonisolated static func defaultVoiceProfileName(_ profileName: String?) -> String {
        profileName ?? "None"
    }

    nonisolated static func queueCount(activeCount: Int, queuedCount: Int) -> String {
        String(max(activeCount, 0) + max(queuedCount, 0))
    }

    nonisolated static func transportSummary(
        state: String,
        host: String?,
        port: Int?,
        path: String?
    ) -> String {
        let address = [host, port.map(String.init)].compactMap { $0 }.joined(separator: ":")
        let resolvedPath = path ?? "/"
        if address.isEmpty {
            return "\(state) at \(resolvedPath)"
        }
        return "\(state) at \(address)\(resolvedPath)"
    }
}

struct SettingsDisplayState: Equatable {
    struct AppInfo: Equatable {
        let buildVersion: String
        let embeddedAutostartStatus: String
    }

    struct RuntimeOverview: Equatable {
        let status: String
        let workerStage: String
        let playbackState: String
        let speechBackend: String
        let defaultVoiceProfileName: String
        let generationQueueCount: String
        let playbackQueueCount: String
    }

    struct TransportRow: Equatable, Identifiable {
        let id: String
        let name: String
        let summary: String
    }

    struct RecentErrorRow: Equatable, Identifiable {
        let id: String
        let source: String
        let message: String
    }

    let appInfo: AppInfo
    let runtimeOverview: RuntimeOverview
    let transports: [TransportRow]
    let recentErrors: [RecentErrorRow]

    nonisolated static func uiTestPopulatedFixture(buildVersion: String) -> SettingsDisplayState {
        SettingsDisplayState(
            appInfo: AppInfo(
                buildVersion: buildVersion,
                embeddedAutostartStatus: SettingsDisplaySupport.enabledStatus(false)
            ),
            runtimeOverview: RuntimeOverview(
                status: "degraded",
                workerStage: "resident_model_ready",
                playbackState: "paused",
                speechBackend: "marvis",
                defaultVoiceProfileName: "fixture-femme",
                generationQueueCount: SettingsDisplaySupport.queueCount(activeCount: 2, queuedCount: 7),
                playbackQueueCount: SettingsDisplaySupport.queueCount(activeCount: 1, queuedCount: 3)
            ),
            transports: [
                TransportRow(
                    id: "fixture-http",
                    name: "HTTP",
                    summary: SettingsDisplaySupport.transportSummary(
                        state: "ready",
                        host: "127.0.0.1",
                        port: 7339,
                        path: "/mcp"
                    )
                ),
            ],
            recentErrors: [
                RecentErrorRow(
                    id: "fixture-runtime",
                    source: "Fixture Runtime",
                    message: "Fixture warning for Settings diagnostics."
                ),
            ]
        )
    }
}
