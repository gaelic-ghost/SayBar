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

    nonisolated static func statusHeadline(
        launchesEmbeddedRuntime: Bool,
        recentErrorMessage: String?,
        startupError: String?,
        playbackState: String,
        workerStage: String,
        serverMode: String
    ) -> String {
        if !launchesEmbeddedRuntime {
            return "SpeakSwiftlyServer startup is skipped for this launch."
        }

        if hasText(recentErrorMessage) {
            return "SpeakSwiftlyServer is running with warnings."
        }

        if hasText(startupError) {
            return "SpeakSwiftlyServer hit a startup problem."
        }

        if playbackState == "playing" {
            return "SpeakSwiftlyServer is playing audio."
        }

        if playbackState == "paused" {
            return "SpeakSwiftlyServer playback is paused."
        }

        if workerStage == "resident_models_unloaded" {
            return "SpeakSwiftlyServer is ready with models unloaded."
        }

        switch serverMode {
            case "broken":
                return "SpeakSwiftlyServer is unavailable."
            case "degraded":
                return "SpeakSwiftlyServer is degraded."
            case "ready":
                return "SpeakSwiftlyServer is ready."
            default:
                return "SpeakSwiftlyServer is starting."
        }
    }

    nonisolated static func statusDetail(
        launchesEmbeddedRuntime: Bool,
        recentErrorMessage: String?,
        startupError: String?,
        playbackState: String,
        activePlaybackRequestID: String?,
        workerStage: String,
        workerReady: Bool,
        serverMode: String
    ) -> String {
        if !launchesEmbeddedRuntime {
            return "SayBar was launched in lightweight test/debug mode, so it has not started the in-process runtime."
        }

        if let recentErrorMessage, !recentErrorMessage.isEmpty {
            return recentErrorMessage
        }

        if let startupError, !startupError.isEmpty {
            return startupError
        }

        if playbackState == "playing", let activePlaybackRequestID {
            return "Playback is active for request \(activePlaybackRequestID)."
        }

        if playbackState == "paused" {
            return "The current playback queue is paused and can resume immediately."
        }

        if workerStage == "resident_models_unloaded" {
            return "Use the power control to load the resident model again before the next speech request."
        }

        if workerReady || serverMode == "ready" {
            return "The embedded runtime is ready for voice, playback, and queue actions."
        }

        switch workerStage {
            case "resident_model_ready":
                return "The embedded runtime is live and the resident model is loaded."
            case "resident_models_unloaded":
                return "The embedded runtime is live, but resident models are currently unloaded."
            case "starting":
                return "The embedded runtime is still starting inside SayBar."
            default:
                return "The embedded runtime is currently reporting worker stage \(workerStage)."
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

    nonisolated static func selectedVoiceProfileName(
        defaultVoiceProfileName: String?,
        firstProfileName: String?
    ) -> String {
        defaultVoiceProfileName ?? firstProfileName ?? ""
    }

    nonisolated static func powerSymbolName(workerStage: String) -> String {
        workerStage == "resident_models_unloaded" ? "power.circle" : "power.circle.fill"
    }

    nonisolated static func playbackSymbolName(playbackState: String) -> String {
        switch playbackState {
            case "playing":
                return "pause.fill"
            case "paused":
                return "play.fill"
            default:
                return "clipboard"
        }
    }

    private nonisolated static func hasText(_ value: String?) -> Bool {
        guard let value else {
            return false
        }

        return !value.isEmpty
    }
}
