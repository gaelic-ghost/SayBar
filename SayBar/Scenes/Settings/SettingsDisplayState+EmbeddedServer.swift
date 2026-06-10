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
                DetailRow(id: "refresh-sequence", label: "Refresh Sequence", value: server.runtimeRefresh.map { String($0.sequenceID) } ?? "None"),
                DetailRow(id: "refresh-source", label: "Refresh Source", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.source)),
                DetailRow(id: "refresh-started", label: "Refresh Started", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.startedAt)),
                DetailRow(id: "generation-refresh", label: "Generation Refreshed", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.generationQueueRefreshedAt)),
                DetailRow(id: "playback-queue-refresh", label: "Playback Queue Refreshed", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.playbackQueueRefreshedAt)),
                DetailRow(id: "playback-state-refresh", label: "Playback State Refreshed", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.playbackStateRefreshedAt)),
                DetailRow(id: "refresh-completed", label: "Refresh Completed", value: SettingsDisplaySupport.fallback(server.runtimeRefresh?.completedAt)),
                DetailRow(id: "backend-transition-state", label: "Backend Transition", value: server.runtimeBackendTransition.state),
                DetailRow(id: "backend-transition-active", label: "Transition Active Backend", value: server.runtimeBackendTransition.activeSpeechBackend),
                DetailRow(id: "backend-transition-requested", label: "Transition Requested Backend", value: SettingsDisplaySupport.fallback(server.runtimeBackendTransition.requestedSpeechBackend)),
                DetailRow(id: "backend-transition-request", label: "Transition Request", value: SettingsDisplaySupport.fallback(server.runtimeBackendTransition.requestID)),
                DetailRow(id: "backend-transition-operation", label: "Transition Operation", value: SettingsDisplaySupport.fallback(server.runtimeBackendTransition.operation)),
                DetailRow(id: "backend-transition-waiting", label: "Transition Waiting", value: SettingsDisplaySupport.fallback(server.runtimeBackendTransition.waitingReason)),
                DetailRow(id: "backend-transition-submitted", label: "Transition Submitted", value: SettingsDisplaySupport.fallback(server.runtimeBackendTransition.submittedAt)),
                DetailRow(id: "backend-transition-started", label: "Transition Started", value: SettingsDisplaySupport.fallback(server.runtimeBackendTransition.startedAt)),
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
            configurationDiagnostics: Self.configurationDiagnostics(from: server.runtimeConfiguration),
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
                Self.transportRow(index: index, transport: transport)
            },
            networkAudioReceiverDiagnostics: Self.networkAudioReceiverDiagnostics(from: server.networkAudioReceiverSelection),
            networkAudioDestinations: Array(server.networkAudioDestinations.enumerated()).map { index, destination in
                Self.networkAudioDestinationRow(index: index, destination: destination)
            },
            recentErrors: Array(server.recentErrors.enumerated()).map { index, error in
                Self.recentErrorRow(index: index, error: error)
            }
        )
    }

    nonisolated static func configurationDiagnostics(
        from configuration: RuntimeConfigurationSnapshot
    ) -> [DetailRow] {
        [
            DetailRow(id: "active-backend", label: "Active Backend", value: configuration.activeRuntimeSpeechBackend),
            DetailRow(id: "next-backend", label: "Next Backend", value: configuration.nextRuntimeSpeechBackend),
            DetailRow(id: "active-duck-media-volume", label: "Active Ducking", value: configuration.activeDuckMediaVolume),
            DetailRow(id: "next-duck-media-volume", label: "Next Ducking", value: configuration.nextDuckMediaVolume),
            DetailRow(id: "active-default-voice", label: "Active Default Voice", value: SettingsDisplaySupport.fallback(configuration.activeDefaultVoiceProfileName)),
            DetailRow(id: "next-default-voice", label: "Next Default Voice", value: SettingsDisplaySupport.fallback(configuration.nextDefaultVoiceProfileName)),
            DetailRow(id: "environment-backend-override", label: "Environment Backend Override", value: SettingsDisplaySupport.fallback(configuration.environmentSpeechBackendOverride)),
            DetailRow(id: "persisted-backend", label: "Persisted Backend", value: SettingsDisplaySupport.fallback(configuration.persistedSpeechBackend)),
            DetailRow(id: "persisted-duck-media-volume", label: "Persisted Ducking", value: SettingsDisplaySupport.fallback(configuration.persistedDuckMediaVolume)),
            DetailRow(id: "persisted-voice", label: "Persisted Voice", value: SettingsDisplaySupport.fallback(configuration.persistedDefaultVoiceProfileName)),
            DetailRow(id: "profile-root", label: "Profile Root", value: configuration.profileRootPath),
            DetailRow(id: "configuration-path", label: "Configuration Path", value: configuration.persistedConfigurationPath),
            DetailRow(id: "configuration-exists", label: "Configuration Exists", value: SettingsDisplaySupport.boolean(configuration.persistedConfigurationExists)),
            DetailRow(id: "configuration-state", label: "Configuration State", value: configuration.persistedConfigurationState),
            DetailRow(id: "configuration-error", label: "Configuration Error", value: SettingsDisplaySupport.fallback(configuration.persistedConfigurationError)),
            DetailRow(id: "configuration-applies-on-restart", label: "Applies On Restart", value: SettingsDisplaySupport.boolean(configuration.persistedConfigurationAppliesOnRestart)),
            DetailRow(id: "active-matches-next", label: "Active Matches Next", value: SettingsDisplaySupport.boolean(configuration.activeRuntimeMatchesNextRuntime)),
            DetailRow(id: "restart-impact", label: "Affects Next Start", value: SettingsDisplaySupport.boolean(configuration.persistedConfigurationWillAffectNextRuntimeStart)),
        ]
    }

    nonisolated static func transportRow(
        index: Int,
        transport: TransportStatusSnapshot
    ) -> TransportRow {
        TransportRow(
            id: "\(index)-\(transport.name)",
            name: transport.name,
            summary: SettingsDisplaySupport.transportSummary(
                state: transport.state,
                host: transport.host,
                port: transport.port,
                path: transport.path
            ),
            enabled: SettingsDisplaySupport.boolean(transport.enabled),
            advertisedAddress: SettingsDisplaySupport.fallback(transport.advertisedAddress),
            activeStreamCount: SettingsDisplaySupport.count(transport.activeStreamCount)
        )
    }

    nonisolated static func networkAudioReceiverDiagnostics(
        from selection: NetworkAudioReceiverSelectionSnapshot
    ) -> [DetailRow] {
        [
            DetailRow(id: "network-audio-selected-destination", label: "Selected Destination", value: SettingsDisplaySupport.fallback(selection.selectedDestinationID)),
            DetailRow(id: "network-audio-available-destinations", label: "Available Destinations", value: String(selection.availableDestinationCount)),
            DetailRow(id: "network-audio-shared-token", label: "Shared Token Configured", value: SettingsDisplaySupport.boolean(selection.sharedTokenConfigured)),
            DetailRow(id: "network-audio-endpoint-ready", label: "Selected Endpoint Ready", value: SettingsDisplaySupport.boolean(selection.selectedDestinationEndpointReady)),
            DetailRow(id: "network-audio-lan-output-ready", label: "LAN Output Ready", value: SettingsDisplaySupport.boolean(selection.lanOutputReady)),
            DetailRow(id: "network-audio-blocked-reasons", label: "Blocked Reasons", value: SettingsDisplaySupport.list(selection.lanOutputBlockedReasons)),
        ]
    }

    nonisolated static func networkAudioDestinationRow(
        index: Int,
        destination: NetworkAudioDestinationSnapshot
    ) -> NetworkAudioDestinationRow {
        NetworkAudioDestinationRow(
            id: destination.id.isEmpty ? "\(index)-network-audio-destination" : destination.id,
            name: destination.name,
            endpoint: SettingsDisplaySupport.networkAudioEndpoint(destination.endpoint),
            capabilities: SettingsDisplaySupport.networkAudioCapabilities(destination.capabilities),
            lastSeen: destination.lastSeen
        )
    }

    nonisolated static func recentErrorRow(
        index: Int,
        error: RecentErrorSnapshot
    ) -> RecentErrorRow {
        RecentErrorRow(
            id: "\(index)-\(error.source)",
            source: error.source,
            code: error.code,
            occurredAt: error.occurredAt,
            message: error.message
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
