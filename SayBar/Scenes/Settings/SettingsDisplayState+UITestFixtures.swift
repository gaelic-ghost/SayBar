//
//  SettingsDisplayState+UITestFixtures.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

extension SettingsDisplayState {
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
