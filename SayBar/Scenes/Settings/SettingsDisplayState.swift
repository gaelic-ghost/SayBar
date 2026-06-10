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

    struct DetailRow: Equatable, Identifiable {
        let id: String
        let label: String
        let value: String
    }

    struct QueueDiagnostics: Equatable, Identifiable {
        let id: String
        let title: String
        let summary: String
        let activeRequests: [RequestRow]
        let queuedRequests: [RequestRow]
    }

    struct RequestRow: Equatable, Identifiable {
        let id: String
        let state: String
        let operation: String
        let profileName: String
    }

    struct GenerationJobRow: Equatable, Identifiable {
        let id: String
        let operation: String
        let profileName: String
        let latestStage: String
        let elapsed: String
    }

    struct TransportRow: Equatable, Identifiable {
        let id: String
        let name: String
        let summary: String
        let enabled: String
        let advertisedAddress: String
        let activeStreamCount: String
    }

    struct NetworkAudioDestinationRow: Equatable, Identifiable {
        let id: String
        let name: String
        let endpoint: String
        let capabilities: String
        let lastSeen: String
    }

    struct RecentErrorRow: Equatable, Identifiable {
        let id: String
        let source: String
        let code: String
        let occurredAt: String
        let message: String
    }

    let appInfo: AppInfo
    let runtimeOverview: RuntimeOverview
    let runtimeDiagnostics: [DetailRow]
    let playbackDiagnostics: [DetailRow]
    let configurationDiagnostics: [DetailRow]
    let queues: [QueueDiagnostics]
    let generationJobs: [GenerationJobRow]
    let transports: [TransportRow]
    let networkAudioReceiverDiagnostics: [DetailRow]
    let networkAudioDestinations: [NetworkAudioDestinationRow]
    let recentErrors: [RecentErrorRow]
}
