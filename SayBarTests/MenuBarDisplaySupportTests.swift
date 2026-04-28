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

    func testStatusDetailPrioritizesActionThenErrorsThenPlayback() {
        XCTAssertEqual(
            MenuBarDisplaySupport.statusDetail(
                autostartEnabled: true,
                actionMessage: "Queued clipboard text for live speech.",
                recentErrorMessage: "Transport warning",
                startupError: "Startup failed",
                playbackState: "playing",
                activePlaybackRequestID: "request-1",
                workerStage: "resident_model_ready",
                workerReady: true,
                serverMode: "ready"
            ),
            "Queued clipboard text for live speech."
        )

        XCTAssertEqual(
            MenuBarDisplaySupport.statusDetail(
                autostartEnabled: true,
                actionMessage: nil,
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
                actionMessage: nil,
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
                actionMessage: nil,
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

    func testQueueSlotCountClampsToDisplayRange() {
        XCTAssertEqual(MenuBarDisplaySupport.queueSlotCount(activeCount: 2, queuedCount: 3), 5)
        XCTAssertEqual(MenuBarDisplaySupport.queueSlotCount(activeCount: 7, queuedCount: 4), 8)
        XCTAssertEqual(MenuBarDisplaySupport.queueSlotCount(activeCount: -3, queuedCount: 1), 0)
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
