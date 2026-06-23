@testable import SayBar
import SpeakSwiftly
import TextForSpeech
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

    func testClipboardSpeechRequestContextIdentifiesSayBarClipboardAction() {
        let context = MenuBarActionSupport.clipboardSpeechRequestContext()

        XCTAssertEqual(context.reqPurpose, .speech)
        XCTAssertEqual(context.source, "Clipboard via SayBar")
        XCTAssertNil(context.topic)
        XCTAssertEqual(context.attributes["saybar.action"], "clipboard_speech")
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
            to: .qwen3_smol_4bit,
            switchSpeechBackend: { backend in
                requestedBackend = backend
            }
        )

        XCTAssertEqual(requestedBackend, .qwen3_smol_4bit)
        XCTAssertEqual(backendName, "qwen3_smol_4bit")
    }

    func testQueueClipboardSpeechSkipsEmptyClipboardAndQueuesTrimmedText() async throws {
        var queuedTexts: [String] = []
        var queuedContexts: [SpeakSwiftly.RequestContext] = []
        let emptyResult = try await MenuBarActionSupport.queueClipboardSpeech(
            clipboardText: " \n\t ",
            queueLiveSpeech: { text, context in
                queuedTexts.append(text)
                queuedContexts.append(context)
            }
        )

        XCTAssertEqual(emptyResult, .emptyClipboard)
        XCTAssertTrue(queuedTexts.isEmpty)
        XCTAssertTrue(queuedContexts.isEmpty)

        let queuedResult = try await MenuBarActionSupport.queueClipboardSpeech(
            clipboardText: "\nSpeak this, please. ",
            queueLiveSpeech: { text, context in
                queuedTexts.append(text)
                queuedContexts.append(context)
            }
        )

        XCTAssertEqual(queuedResult, .queued)
        XCTAssertEqual(queuedTexts, ["Speak this, please."])
        XCTAssertEqual(queuedContexts, [MenuBarActionSupport.clipboardSpeechRequestContext()])
    }

    func testClearPlaybackQueueSkipsWhenNoQueuedRequestsAreVisible() async throws {
        var clearCallCount = 0
        let result = try await MenuBarActionSupport.clearPlaybackQueue(
            queuedCount: 0,
            clearPlaybackQueue: {
                clearCallCount += 1
                return 3
            }
        )

        XCTAssertEqual(result, .skipped)
        XCTAssertEqual(clearCallCount, 0)
    }

    func testClearPlaybackQueueCallsServerWhenQueuedRequestsAreVisible() async throws {
        var clearCallCount = 0
        let result = try await MenuBarActionSupport.clearPlaybackQueue(
            queuedCount: 2,
            clearPlaybackQueue: {
                clearCallCount += 1
                return 2
            }
        )

        XCTAssertEqual(result, .cleared(2))
        XCTAssertEqual(clearCallCount, 1)
    }

    func testCancelPlaybackRequestSkipsEmptyRequestID() async throws {
        var canceledIDs: [String] = []
        let result = try await MenuBarActionSupport.cancelPlaybackRequest(
            requestID: "",
            cancelPlaybackRequest: { requestID in
                canceledIDs.append(requestID)
                return requestID
            }
        )

        XCTAssertEqual(result, .skipped)
        XCTAssertTrue(canceledIDs.isEmpty)
    }

    func testCancelPlaybackRequestCallsServerWithRequestID() async throws {
        var canceledIDs: [String] = []
        let result = try await MenuBarActionSupport.cancelPlaybackRequest(
            requestID: "request-123",
            cancelPlaybackRequest: { requestID in
                canceledIDs.append(requestID)
                return "canceled-\(requestID)"
            }
        )

        XCTAssertEqual(result, .canceled("canceled-request-123"))
        XCTAssertEqual(canceledIDs, ["request-123"])
    }
}
