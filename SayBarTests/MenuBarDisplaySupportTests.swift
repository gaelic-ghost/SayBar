@testable import SayBar
import XCTest

final class MenuBarDisplaySupportTests: XCTestCase {
    func testStatusHeadlineShowsIdleWhenAutostartIsDisabled() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: false,
                recentErrorMessage: "Recent warning",
                startupError: "Startup failed",
                playbackState: "playing",
                workerStage: "resident_model_ready",
                serverMode: "ready"
            ),
            "SpeakSwiftlyServer is idle for this launch."
        )
    }

    func testStatusHeadlinePrioritizesRecentErrorBeforeStartupAndPlayback() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: "Transport warning",
                startupError: "Startup failed",
                playbackState: "playing",
                workerStage: "resident_model_ready",
                serverMode: "ready"
            ),
            "SpeakSwiftlyServer is running with warnings."
        )
    }

    func testStatusHeadlinePrioritizesStartupErrorBeforePlayback() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: "Startup failed",
                playbackState: "playing",
                workerStage: "resident_model_ready",
                serverMode: "ready"
            ),
            "SpeakSwiftlyServer hit a startup problem."
        )
    }

    func testStatusHeadlineMapsPlaybackAndRuntimeStates() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "playing",
                workerStage: "resident_model_ready",
                serverMode: "ready"
            ),
            "SpeakSwiftlyServer is playing audio."
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "idle",
                workerStage: "resident_models_unloaded",
                serverMode: "ready"
            ),
            "SpeakSwiftlyServer is ready with models unloaded."
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "idle",
                workerStage: "starting",
                serverMode: "broken"
            ),
            "SpeakSwiftlyServer is unavailable."
        )
    }

    func testStatusHeadlineMapsServerModesAfterHigherPriorityStates() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "idle",
                workerStage: "resident_model_ready",
                serverMode: "degraded"
            ),
            "SpeakSwiftlyServer is degraded."
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "idle",
                workerStage: "resident_model_ready",
                serverMode: "ready"
            ),
            "SpeakSwiftlyServer is ready."
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.statusHeadline(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "idle",
                workerStage: "starting",
                serverMode: "starting"
            ),
            "SpeakSwiftlyServer is starting."
        )
    }

    func testStatusDetailPrioritizesErrorsThenPlayback() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusDetail(
                autostartEnabled: true,
                recentErrorMessage: "Transport warning",
                startupError: "Startup failed",
                playbackState: "playing",
                activePlaybackRequestID: "request-1",
                workerStage: "resident_model_ready",
                workerReady: true,
                serverMode: "ready"
            ),
            "Transport warning"
        )
    }

    func testStatusDetailMapsReadyAndWorkerStages() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusDetail(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "paused",
                activePlaybackRequestID: nil,
                workerStage: "resident_model_ready",
                workerReady: true,
                serverMode: "ready"
            ),
            "The current playback queue is paused and can resume immediately."
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.statusDetail(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "idle",
                activePlaybackRequestID: nil,
                workerStage: "resident_model_ready",
                workerReady: false,
                serverMode: "starting"
            ),
            "The embedded runtime is live and the resident model is loaded."
        )
    }

    func testStatusDetailMapsActivePlaybackAndFallbackWorkerStage() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusDetail(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "playing",
                activePlaybackRequestID: "request-1",
                workerStage: "resident_model_ready",
                workerReady: true,
                serverMode: "ready"
            ),
            "Playback is active for request request-1."
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.statusDetail(
                autostartEnabled: true,
                recentErrorMessage: nil,
                startupError: nil,
                playbackState: "idle",
                activePlaybackRequestID: nil,
                workerStage: "warming_cache",
                workerReady: false,
                serverMode: "starting"
            ),
            "The embedded runtime is currently reporting worker stage warming_cache."
        )
    }

    func testQueueSummaryNormalizesCountsAndDefaultsToTwentyFourSlots() {
        let summary = MenuBarDisplaySupport.queueSummary(activeCount: 2, queuedCount: 3)

        XCTAssertEqual(summary.activeCount, 2)
        XCTAssertEqual(summary.queuedCount, 3)
        XCTAssertEqual(summary.totalCount, 5)
        XCTAssertEqual(summary.capacity, 24)
        XCTAssertEqual(summary.visibleActiveSlotCount, 2)
        XCTAssertEqual(summary.visibleQueuedSlotCount, 3)
    }

    func testQueueSummaryClampsVisibleSlotsToCapacity() {
        let summary = MenuBarDisplaySupport.queueSummary(activeCount: 20, queuedCount: 8)

        XCTAssertEqual(summary.totalCount, 24)
        XCTAssertEqual(summary.visibleActiveSlotCount, 20)
        XCTAssertEqual(summary.visibleQueuedSlotCount, 4)
    }

    func testQueueSummaryClampsActiveSlotsBeforeQueuedSlots() {
        let summary = MenuBarDisplaySupport.queueSummary(activeCount: 30, queuedCount: 8)

        XCTAssertEqual(summary.totalCount, 24)
        XCTAssertEqual(summary.visibleActiveSlotCount, 24)
        XCTAssertEqual(summary.visibleQueuedSlotCount, 0)
    }

    func testQueueSummaryDropsNegativeCountsAndCapacity() {
        let summary = MenuBarDisplaySupport.queueSummary(activeCount: -3, queuedCount: 1, capacity: -1)

        XCTAssertEqual(summary.activeCount, 0)
        XCTAssertEqual(summary.queuedCount, 1)
        XCTAssertEqual(summary.totalCount, 0)
        XCTAssertEqual(summary.capacity, 0)
        XCTAssertEqual(summary.visibleActiveSlotCount, 0)
        XCTAssertEqual(summary.visibleQueuedSlotCount, 0)
    }

    func testSelectedVoiceProfilePrefersDefaultThenFirstProfileThenEmptyString() {
        XCTAssertEqual(
            MenuBarDisplaySupport.selectedVoiceProfileName(
                defaultVoiceProfileName: "default-femme",
                firstProfileName: "bright-femme"
            ),
            "default-femme"
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.selectedVoiceProfileName(
                defaultVoiceProfileName: nil,
                firstProfileName: "bright-femme"
            ),
            "bright-femme"
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.selectedVoiceProfileName(
                defaultVoiceProfileName: nil,
                firstProfileName: nil
            ),
            ""
        )
    }

    func testControlSymbolsReflectRuntimeAndPlaybackStates() {
        XCTAssertEqual(
            MenuBarDisplaySupport.powerSymbolName(workerStage: "resident_models_unloaded"),
            "power.circle"
        )
        XCTAssertEqual(
            MenuBarDisplaySupport.powerSymbolName(workerStage: "resident_model_ready"),
            "power.circle.fill"
        )
        XCTAssertEqual(MenuBarDisplaySupport.playbackSymbolName(playbackState: "playing"), "pause.fill")
        XCTAssertEqual(MenuBarDisplaySupport.playbackSymbolName(playbackState: "paused"), "play.fill")
        XCTAssertEqual(MenuBarDisplaySupport.playbackSymbolName(playbackState: "idle"), "clipboard")
    }
}
