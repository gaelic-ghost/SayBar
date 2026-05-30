//
//  SettingsDisplayState+EmbeddedServer.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SpeakSwiftlyServer

extension SettingsDisplayState {
    init(server: EmbeddedServer, buildVersion: String) {
        self.init(
            appInfo: AppInfo(
                buildVersion: buildVersion
            ),
            runtimeOverview: RuntimeOverview(
                status: server.overview.serverMode,
                workerStage: server.overview.workerStage,
                playbackState: server.playback.state,
                speechBackend: server.runtimeConfiguration.activeRuntimeSpeechBackend,
                defaultVoiceProfileName: SettingsDisplaySupport.defaultVoiceProfileName(server.overview.defaultVoiceProfileName),
                generationQueueCount: SettingsDisplaySupport.queueCount(
                    activeCount: server.generationQueue.activeCount,
                    queuedCount: server.generationQueue.queuedCount
                ),
                playbackQueueCount: SettingsDisplaySupport.queueCount(
                    activeCount: server.playbackQueue.activeCount,
                    queuedCount: server.playbackQueue.queuedCount
                )
            ),
            runtimeDiagnostics: [
                DetailRow(id: "service", label: "Service", value: server.overview.service),
                DetailRow(id: "environment", label: "Environment", value: server.overview.environment),
                DetailRow(id: "worker-mode", label: "Worker Mode", value: server.overview.workerMode),
                DetailRow(id: "worker-ready", label: "Worker Ready", value: SettingsDisplaySupport.boolean(server.overview.workerReady)),
                DetailRow(id: "profile-cache-state", label: "Profile Cache", value: server.overview.profileCacheState),
                DetailRow(id: "profile-count", label: "Profile Count", value: String(server.overview.profileCount)),
                DetailRow(id: "profile-cache-warning", label: "Profile Warning", value: SettingsDisplaySupport.fallback(server.overview.profileCacheWarning)),
                DetailRow(id: "last-profile-refresh", label: "Last Profile Refresh", value: SettingsDisplaySupport.fallback(server.overview.lastProfileRefreshAt)),
                DetailRow(id: "refresh-source", label: "Refresh Source", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.source)),
                DetailRow(id: "refresh-completed", label: "Refresh Completed", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.completedAt)),
            ],
            playbackDiagnostics: [
                DetailRow(id: "playback-sequence", label: "Sequence", value: server.playback.sequence.map(String.init) ?? "None"),
                DetailRow(id: "playback-updated", label: "Updated", value: SettingsDisplaySupport.fallback(server.playback.updatedAt)),
                DetailRow(id: "playback-stable", label: "Stable For Generation", value: SettingsDisplaySupport.boolean(server.playback.isStableForConcurrentGeneration)),
                DetailRow(id: "playback-rebuffering", label: "Rebuffering", value: SettingsDisplaySupport.boolean(server.playback.isRebuffering)),
                DetailRow(id: "playback-buffered", label: "Buffered Audio", value: server.playback.stableBufferedAudioMS.map { "\($0) ms" } ?? "None"),
                DetailRow(id: "playback-buffer-target", label: "Buffer Target", value: server.playback.stableBufferTargetMS.map { "\($0) ms" } ?? "None"),
                DetailRow(id: "playback-event", label: "Latest Event", value: SettingsDisplaySupport.fallback(server.playback.latestEvent?.event)),
                DetailRow(id: "playback-device", label: "Current Device", value: SettingsDisplaySupport.fallback(server.playback.latestEvent?.currentDevice)),
            ],
            configurationDiagnostics: [
                DetailRow(id: "active-backend", label: "Active Backend", value: server.runtimeConfiguration.activeRuntimeSpeechBackend),
                DetailRow(id: "next-backend", label: "Next Backend", value: server.runtimeConfiguration.nextRuntimeSpeechBackend),
                DetailRow(id: "active-default-voice", label: "Active Default Voice", value: SettingsDisplaySupport.fallback(server.runtimeConfiguration.activeDefaultVoiceProfileName)),
                DetailRow(id: "next-default-voice", label: "Next Default Voice", value: SettingsDisplaySupport.fallback(server.runtimeConfiguration.nextDefaultVoiceProfileName)),
                DetailRow(id: "persisted-backend", label: "Persisted Backend", value: SettingsDisplaySupport.fallback(server.runtimeConfiguration.persistedSpeechBackend)),
                DetailRow(id: "persisted-voice", label: "Persisted Voice", value: SettingsDisplaySupport.fallback(server.runtimeConfiguration.persistedDefaultVoiceProfileName)),
                DetailRow(id: "profile-root", label: "Profile Root", value: server.runtimeConfiguration.profileRootPath),
                DetailRow(id: "configuration-path", label: "Configuration Path", value: server.runtimeConfiguration.persistedConfigurationPath),
                DetailRow(id: "configuration-state", label: "Configuration State", value: server.runtimeConfiguration.persistedConfigurationState),
                DetailRow(id: "configuration-error", label: "Configuration Error", value: SettingsDisplaySupport.fallback(server.runtimeConfiguration.persistedConfigurationError)),
                DetailRow(id: "active-matches-next", label: "Active Matches Next", value: SettingsDisplaySupport.boolean(server.runtimeConfiguration.activeRuntimeMatchesNextRuntime)),
                DetailRow(id: "restart-impact", label: "Affects Next Start", value: SettingsDisplaySupport.boolean(server.runtimeConfiguration.persistedConfigurationWillAffectNextRuntimeStart)),
            ],
            queues: [
                Self.queueDiagnostics(
                    id: "generation",
                    title: "Generation",
                    activeCount: server.generationQueue.activeCount,
                    queuedCount: server.generationQueue.queuedCount,
                    activeRequests: server.generationQueue.activeRequests,
                    queuedRequests: server.generationQueue.queuedRequests
                ),
                Self.queueDiagnostics(
                    id: "playback",
                    title: "Playback",
                    activeCount: server.playbackQueue.activeCount,
                    queuedCount: server.playbackQueue.queuedCount,
                    activeRequests: server.playbackQueue.activeRequests,
                    queuedRequests: server.playbackQueue.queuedRequests
                ),
            ],
            generationJobs: server.currentGenerationJobs.map { job in
                GenerationJobRow(
                    id: job.jobID,
                    operation: job.op,
                    profileName: SettingsDisplaySupport.fallback(job.profileName),
                    latestStage: SettingsDisplaySupport.fallback(job.latestStage),
                    elapsed: SettingsDisplaySupport.elapsedSeconds(job.elapsedGenerationSeconds)
                )
            },
            transports: Array(server.transports.enumerated()).map { index, transport in
                TransportRow(
                    id: "\(index)-\(transport.name)",
                    name: transport.name,
                    summary: SettingsDisplaySupport.transportSummary(
                        state: transport.state,
                        host: transport.host,
                        port: transport.port,
                        path: transport.path
                    )
                )
            },
            recentErrors: Array(server.recentErrors.enumerated()).map { index, error in
                RecentErrorRow(
                    id: "\(index)-\(error.source)",
                    source: error.source,
                    message: error.message
                )
            }
        )
    }

    private static func queueDiagnostics(
        id: String,
        title: String,
        activeCount: Int,
        queuedCount: Int,
        activeRequests: [ActiveRequestSnapshot],
        queuedRequests: [QueuedRequestSnapshot]
    ) -> QueueDiagnostics {
        QueueDiagnostics(
            id: id,
            title: title,
            summary: SettingsDisplaySupport.queueSummary(
                activeCount: activeCount,
                queuedCount: queuedCount
            ),
            activeRequests: activeRequests.map { request in
                RequestRow(
                    id: request.id,
                    state: "Active",
                    operation: request.op,
                    profileName: SettingsDisplaySupport.fallback(request.profileName)
                )
            },
            queuedRequests: queuedRequests.map { request in
                RequestRow(
                    id: request.id,
                    state: "#\(request.queuePosition)",
                    operation: request.op,
                    profileName: SettingsDisplaySupport.fallback(request.profileName)
                )
            }
        )
    }
}
