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
                buildVersion: buildVersion
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
            runtimeDiagnostics: [
                DetailRow(id: "fixture-service", label: "Service", value: "SayBar UI Fixture"),
                DetailRow(id: "fixture-environment", label: "Environment", value: "ui-test"),
                DetailRow(id: "fixture-worker-mode", label: "Worker Mode", value: "resident"),
                DetailRow(id: "fixture-profile-cache", label: "Profile Cache", value: "loaded"),
            ],
            playbackDiagnostics: [
                DetailRow(id: "fixture-playback-sequence", label: "Sequence", value: "42"),
                DetailRow(id: "fixture-playback-buffered", label: "Buffered Audio", value: "1200 ms"),
            ],
            configurationDiagnostics: [
                DetailRow(id: "fixture-active-backend", label: "Active Backend", value: "marvis"),
                DetailRow(id: "fixture-next-backend", label: "Next Backend", value: "qwen3_smol"),
            ],
            queues: [
                QueueDiagnostics(
                    id: "fixture-generation",
                    title: "Generation",
                    summary: SettingsDisplaySupport.queueSummary(activeCount: 2, queuedCount: 7),
                    activeRequests: [
                        RequestRow(
                            id: "fixture-generation-active",
                            state: "Active",
                            operation: "speak",
                            profileName: "fixture-femme"
                        ),
                    ],
                    queuedRequests: [
                        RequestRow(
                            id: "fixture-generation-queued",
                            state: "#1",
                            operation: "audio_file",
                            profileName: "fixture-femme"
                        ),
                    ]
                ),
                QueueDiagnostics(
                    id: "fixture-playback",
                    title: "Playback",
                    summary: SettingsDisplaySupport.queueSummary(activeCount: 1, queuedCount: 3),
                    activeRequests: [],
                    queuedRequests: []
                ),
            ],
            generationJobs: [
                GenerationJobRow(
                    id: "fixture-job",
                    operation: "speak",
                    profileName: "fixture-femme",
                    latestStage: "generating_audio",
                    elapsed: "1.8 seconds"
                ),
            ],
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
