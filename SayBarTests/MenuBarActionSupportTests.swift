@testable import SayBar
import SpeakSwiftly
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

    func testRefreshVoiceProfilesRunsOnlyWhenCacheIsEmpty() async throws {
        var refreshCallCount = 0
        let refreshed = try await MenuBarActionSupport.refreshVoiceProfilesIfNeeded(
            voiceProfilesAreEmpty: true,
            refreshVoiceProfiles: {
                refreshCallCount += 1
            }
        )

        XCTAssertTrue(refreshed)
        XCTAssertEqual(refreshCallCount, 1)

        let skipped = try await MenuBarActionSupport.refreshVoiceProfilesIfNeeded(
            voiceProfilesAreEmpty: false,
            refreshVoiceProfiles: {
                refreshCallCount += 1
            }
        )

        XCTAssertFalse(skipped)
        XCTAssertEqual(refreshCallCount, 1)
    }

    func testSetDefaultVoiceProfileSkipsEmptySelectionAndReturnsResolvedProfile() async throws {
        var requestedProfileNames: [String] = []
        let skippedProfileName = try await MenuBarActionSupport.setDefaultVoiceProfile(
            profileName: "",
            setDefaultVoiceProfileName: { profileName in
                requestedProfileNames.append(profileName)
                return profileName
            }
        )

        XCTAssertNil(skippedProfileName)
        XCTAssertTrue(requestedProfileNames.isEmpty)

        let resolvedProfileName = try await MenuBarActionSupport.setDefaultVoiceProfile(
            profileName: "default-femme",
            setDefaultVoiceProfileName: { profileName in
                requestedProfileNames.append(profileName)
                return "resolved-\(profileName)"
            }
        )

        XCTAssertEqual(resolvedProfileName, "resolved-default-femme")
        XCTAssertEqual(requestedProfileNames, ["default-femme"])
    }

    func testSwitchSpeechBackendCallsServerActionAndReturnsBackendName() async throws {
        var requestedBackend: SpeakSwiftly.SpeechBackend?
        let backendName = try await MenuBarActionSupport.switchSpeechBackend(
            to: .marvis,
            switchSpeechBackend: { backend in
                requestedBackend = backend
            }
        )

        XCTAssertEqual(requestedBackend, .marvis)
        XCTAssertEqual(backendName, "marvis")
    }

    func testQueueClipboardSpeechSkipsEmptyClipboardAndQueuesTrimmedText() async throws {
        var queuedTexts: [String] = []
        let emptyResult = try await MenuBarActionSupport.queueClipboardSpeech(
            clipboardText: " \n\t ",
            queueLiveSpeech: { text in
                queuedTexts.append(text)
            }
        )

        XCTAssertEqual(emptyResult, .emptyClipboard)
        XCTAssertTrue(queuedTexts.isEmpty)

        let queuedResult = try await MenuBarActionSupport.queueClipboardSpeech(
            clipboardText: "\nSpeak this, please. ",
            queueLiveSpeech: { text in
                queuedTexts.append(text)
            }
        )

        XCTAssertEqual(queuedResult, .queued)
        XCTAssertEqual(queuedTexts, ["Speak this, please."])
    }
}
