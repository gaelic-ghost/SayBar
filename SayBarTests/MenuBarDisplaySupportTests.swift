@testable import SayBar
import XCTest

@MainActor
final class MenuBarDisplaySupportTests: XCTestCase {
    func testStatusHeadlineShowsSkippedStartupWhenRuntimeLaunchIsDisabled() {
        let status = menuStatus(
            launchesEmbeddedRuntime: false,
            recentErrorMessage: "Recent warning",
            startupError: "Startup failed",
            playbackState: "playing",
            workerStage: "resident_model_ready",
            serverMode: "ready"
        )

        XCTAssertEqual(status, .startupSkipped)
        XCTAssertEqual(status.headline, "SpeakSwiftlyServer startup is skipped for this launch.")
    }

    func testStatusHeadlinePrioritizesRecentErrorBeforeStartupAndPlayback() {
        let status = menuStatus(
            recentErrorMessage: "Transport warning",
            startupError: "Startup failed",
            playbackState: "playing",
            workerStage: "resident_model_ready",
            serverMode: "ready"
        )

        XCTAssertEqual(status, .warning("Transport warning"))
        XCTAssertEqual(status.headline, "SpeakSwiftlyServer is running with warnings.")
    }

    func testStatusHeadlinePrioritizesStartupErrorBeforePlayback() {
        let status = menuStatus(
            startupError: "Startup failed",
            playbackState: "playing",
            workerStage: "resident_model_ready",
            serverMode: "ready"
        )

        XCTAssertEqual(status, .startupProblem("Startup failed"))
        XCTAssertEqual(status.headline, "SpeakSwiftlyServer hit a startup problem.")
    }

    func testStatusHeadlineMapsPlaybackAndRuntimeStates() {
        XCTAssertEqual(
            menuStatus(
                playbackState: "playing",
                workerStage: "resident_model_ready",
                serverMode: "ready"
            ).headline,
            "SpeakSwiftlyServer is playing audio."
        )

        XCTAssertEqual(
            menuStatus(
                playbackState: "idle",
                workerStage: "resident_models_unloaded",
                serverMode: "ready"
            ).headline,
            "SpeakSwiftlyServer is ready with models unloaded."
        )

        XCTAssertEqual(
            menuStatus(
                playbackState: "idle",
                workerStage: "starting",
                serverMode: "broken"
            ).headline,
            "SpeakSwiftlyServer is unavailable."
        )
    }

    func testStatusHeadlineMapsServerModesAfterHigherPriorityStates() {
        XCTAssertEqual(
            menuStatus(
                playbackState: "idle",
                workerStage: "resident_model_ready",
                serverMode: "degraded"
            ).headline,
            "SpeakSwiftlyServer is degraded."
        )

        XCTAssertEqual(
            menuStatus(
                playbackState: "idle",
                workerStage: "resident_model_ready",
                serverMode: "ready"
            ).headline,
            "SpeakSwiftlyServer is ready."
        )

        XCTAssertEqual(
            menuStatus(
                playbackState: "idle",
                workerStage: "starting",
                serverMode: "starting"
            ).headline,
            "SpeakSwiftlyServer is starting."
        )
    }

    func testStatusDetailPrioritizesErrorsThenPlayback() {
        let status = menuStatus(
            recentErrorMessage: "Transport warning",
            startupError: "Startup failed",
            playbackState: "playing",
            activePlaybackRequestID: "request-1",
            workerStage: "resident_model_ready",
            workerReady: true,
            serverMode: "ready"
        )

        XCTAssertEqual(status, .warning("Transport warning"))
        XCTAssertEqual(status.detail, "Transport warning")
    }

    func testStatusDetailMapsReadyAndWorkerStages() {
        XCTAssertEqual(
            menuStatus(
                playbackState: "paused",
                workerStage: "resident_model_ready",
                workerReady: true,
                serverMode: "ready"
            ).detail,
            "The current playback queue is paused and can resume immediately."
        )

        XCTAssertEqual(
            menuStatus(
                playbackState: "idle",
                workerStage: "resident_model_ready",
                workerReady: false,
                serverMode: "starting"
            ).detail,
            "The embedded runtime is live and the resident model is loaded."
        )
    }

    func testStatusDetailMapsActivePlaybackAndFallbackWorkerStage() {
        XCTAssertEqual(
            menuStatus(
                playbackState: "playing",
                activePlaybackRequestID: "request-1",
                workerStage: "resident_model_ready",
                workerReady: true,
                serverMode: "ready"
            ).detail,
            "Playback is active for request request-1."
        )

        XCTAssertEqual(
            menuStatus(
                playbackState: "idle",
                workerStage: "warming_cache",
                workerReady: false,
                serverMode: "starting"
            ).detail,
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

    private func menuStatus(
        launchesEmbeddedRuntime: Bool = true,
        recentErrorMessage: String? = nil,
        startupError: String? = nil,
        playbackState: String = "idle",
        activePlaybackRequestID: String? = nil,
        workerStage: String = "starting",
        workerReady: Bool = false,
        serverMode: String = "starting"
    ) -> MenuBarStatus {
        MenuBarStatus(
            launchesEmbeddedRuntime: launchesEmbeddedRuntime,
            recentErrorMessage: recentErrorMessage,
            startupError: startupError,
            playbackState: playbackState,
            activePlaybackRequestID: activePlaybackRequestID,
            workerStage: workerStage,
            workerReady: workerReady,
            serverMode: serverMode
        )
    }
}
