@testable import SayBar
import XCTest

@MainActor
final class MenuBarActionSupportTests: XCTestCase {
    func testResidentModelCommandReloadsOnlyWhenModelsAreUnloaded() {
        XCTAssertEqual(
            MenuBarActionSupport.residentModelCommand(workerStage: "resident_models_unloaded"),
            .reload
        )
        XCTAssertEqual(
            MenuBarActionSupport.residentModelCommand(workerStage: "resident_model_ready"),
            .unload
        )
        XCTAssertEqual(
            MenuBarActionSupport.residentModelCommand(workerStage: "starting"),
            .unload
        )
    }

    func testPlaybackCommandRoutesPlayingPausedAndIdleStates() {
        XCTAssertEqual(MenuBarActionSupport.playbackCommand(playbackState: "playing"), .pause)
        XCTAssertEqual(MenuBarActionSupport.playbackCommand(playbackState: "paused"), .resume)
        XCTAssertEqual(MenuBarActionSupport.playbackCommand(playbackState: "idle"), .submitClipboardSpeech)
        XCTAssertEqual(MenuBarActionSupport.playbackCommand(playbackState: "stopped"), .submitClipboardSpeech)
    }

    func testNormalizedClipboardTextTrimsWhitespaceAndNil() {
        XCTAssertEqual(MenuBarActionSupport.normalizedClipboardText("  Speak this.\n"), "Speak this.")
        XCTAssertEqual(MenuBarActionSupport.normalizedClipboardText("\n\t "), "")
        XCTAssertEqual(MenuBarActionSupport.normalizedClipboardText(nil), "")
    }
}
