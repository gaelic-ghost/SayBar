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
                speechBackend: "qwen3_smol_4bit",
                defaultVoiceProfileName: "fixture-femme",
                generationQueueCount: SettingsDisplaySupport.queueCount(activeCount: 2, queuedCount: 7),
                playbackQueueCount: SettingsDisplaySupport.queueCount(activeCount: 1, queuedCount: 3)
            ),
            runtimeDiagnostics: [
                DetailRow(id: "fixture-service", label: "Service", value: "SayBar UI Fixture"),
                DetailRow(id: "fixture-environment", label: "Environment", value: "ui-test"),
                DetailRow(id: "fixture-worker-mode", label: "Worker Mode", value: "resident"),
                DetailRow(id: "fixture-profile-cache", label: "Profile Cache", value: "loaded"),
                DetailRow(id: "fixture-backend-transition-state", label: "Backend Transition", value: "idle"),
            ],
            playbackDiagnostics: [
                DetailRow(id: "fixture-playback-sequence", label: "Sequence", value: "42"),
                DetailRow(id: "fixture-playback-buffered", label: "Buffered Audio", value: "1200 ms"),
            ],
            configurationDiagnostics: [
                DetailRow(id: "fixture-active-backend", label: "Active Backend", value: "qwen3_smol_4bit"),
                DetailRow(id: "fixture-next-backend", label: "Next Backend", value: "qwen3_smol"),
                DetailRow(id: "fixture-active-duck-media-volume", label: "Active Ducking", value: "medium"),
                DetailRow(id: "fixture-next-duck-media-volume", label: "Next Ducking", value: "soft"),
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
                    ),
                    enabled: "Yes",
                    advertisedAddress: "http://127.0.0.1:7339",
                    activeStreamCount: "2"
                ),
            ],
            networkAudioReceiverDiagnostics: [
                DetailRow(id: "fixture-network-audio-selected-destination", label: "Selected Destination", value: "fixture-speaker"),
                DetailRow(id: "fixture-network-audio-available-destinations", label: "Available Destinations", value: "1"),
                DetailRow(id: "fixture-network-audio-shared-token", label: "Shared Token Configured", value: "Yes"),
                DetailRow(id: "fixture-network-audio-endpoint-ready", label: "Selected Endpoint Ready", value: "Yes"),
                DetailRow(id: "fixture-network-audio-lan-output-ready", label: "LAN Output Ready", value: "Yes"),
                DetailRow(id: "fixture-network-audio-blocked-reasons", label: "Blocked Reasons", value: "None"),
            ],
            networkAudioDestinations: [
                NetworkAudioDestinationRow(
                    id: "fixture-speaker",
                    name: "Fixture Speaker",
                    endpoint: "fixture-speaker.local",
                    capabilities: "v1; pcm_f32; 24000 Hz; 1 channel(s)",
                    lastSeen: "2026-06-06T12:00:00Z"
                ),
            ],
            recentErrors: [
                RecentErrorRow(
                    id: "fixture-runtime",
                    source: "Fixture Runtime",
                    code: "fixture_warning",
                    occurredAt: "2026-06-06T12:01:00Z",
                    message: "Fixture warning for Settings diagnostics."
                ),
            ]
        )
    }
}
