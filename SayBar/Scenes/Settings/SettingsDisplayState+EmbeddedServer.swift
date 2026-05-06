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
}
