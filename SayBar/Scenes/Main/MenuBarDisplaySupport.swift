//
//  MenuBarDisplaySupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

enum MenuBarDisplaySupport {
    struct QueueSummary: Equatable {
        nonisolated let activeCount: Int
        nonisolated let queuedCount: Int
        nonisolated let totalCount: Int
        nonisolated let capacity: Int

        nonisolated var visibleActiveSlotCount: Int {
            min(activeCount, capacity)
        }

        nonisolated var visibleQueuedSlotCount: Int {
            min(queuedCount, max(capacity - visibleActiveSlotCount, 0))
        }
    }

    nonisolated static func queueSummary(
        activeCount: Int,
        queuedCount: Int,
        capacity: Int = 24
    ) -> QueueSummary {
        let normalizedActiveCount = max(activeCount, 0)
        let normalizedQueuedCount = max(queuedCount, 0)
        let normalizedCapacity = max(capacity, 0)
        return QueueSummary(
            activeCount: normalizedActiveCount,
            queuedCount: normalizedQueuedCount,
            totalCount: min(normalizedActiveCount + normalizedQueuedCount, normalizedCapacity),
            capacity: normalizedCapacity
        )
    }
}

enum MenuBarStatus: Equatable {
    case startupSkipped
    case warning(String)
    case startupProblem(String)
    case playing(requestID: String?)
    case paused
    case modelsUnloaded
    case unavailable
    case degraded
    case ready
    case modelReady
    case starting(workerStage: String)

    nonisolated init(
        launchesEmbeddedRuntime: Bool,
        recentErrorMessage: String?,
        startupError: String?,
        playbackState: String,
        activePlaybackRequestID: String?,
        workerStage: String,
        workerReady: Bool,
        serverMode: String
    ) {
        if !launchesEmbeddedRuntime {
            self = .startupSkipped
        } else if let recentErrorMessage, !recentErrorMessage.isEmpty {
            self = .warning(recentErrorMessage)
        } else if let startupError, !startupError.isEmpty {
            self = .startupProblem(startupError)
        } else if playbackState == "playing" {
            self = .playing(requestID: activePlaybackRequestID)
        } else if playbackState == "paused" {
            self = .paused
        } else if workerStage == "resident_models_unloaded" {
            self = .modelsUnloaded
        } else if serverMode == "broken" {
            self = .unavailable
        } else if serverMode == "degraded" {
            self = .degraded
        } else if workerReady || serverMode == "ready" {
            self = .ready
        } else if workerStage == "resident_model_ready" {
            self = .modelReady
        } else {
            self = .starting(workerStage: workerStage)
        }
    }

    nonisolated var headline: String {
        switch self {
            case .startupSkipped:
                return "SpeakSwiftlyServer startup is skipped for this launch."
            case .warning:
                return "SpeakSwiftlyServer is running with warnings."
            case .startupProblem:
                return "SpeakSwiftlyServer hit a startup problem."
            case .playing:
                return "SpeakSwiftlyServer is playing audio."
            case .paused:
                return "SpeakSwiftlyServer playback is paused."
            case .modelsUnloaded:
                return "SpeakSwiftlyServer is ready with models unloaded."
            case .unavailable:
                return "SpeakSwiftlyServer is unavailable."
            case .degraded:
                return "SpeakSwiftlyServer is degraded."
            case .ready:
                return "SpeakSwiftlyServer is ready."
            case .modelReady, .starting:
                return "SpeakSwiftlyServer is starting."
        }
    }

    nonisolated var detail: String {
        switch self {
            case .startupSkipped:
                return "SayBar was launched in lightweight test/debug mode, so it has not started the in-process runtime."
            case .warning(let message), .startupProblem(let message):
                return message
            case .playing(let requestID):
                if let requestID {
                    return "Playback is active for request \(requestID)."
                }
                return "Playback is active."
            case .paused:
                return "The current playback queue is paused and can resume immediately."
            case .modelsUnloaded:
                return "Use the power control to load the resident model again before the next speech request."
            case .ready:
                return "The embedded runtime is ready for voice, playback, and queue actions."
            case .modelReady:
                return "The embedded runtime is live and the resident model is loaded."
            case .unavailable:
                return "The embedded runtime is unavailable."
            case .degraded:
                return "The embedded runtime is degraded."
            case .starting(let workerStage):
                if workerStage == "starting" {
                    return "The embedded runtime is still starting inside SayBar."
                }
                return "The embedded runtime is currently reporting worker stage \(workerStage)."
        }
    }
}
