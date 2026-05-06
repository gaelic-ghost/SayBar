//
//  SettingsDisplayState.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

struct SettingsDisplayState: Equatable {
    struct AppInfo: Equatable {
        let buildVersion: String
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
}
