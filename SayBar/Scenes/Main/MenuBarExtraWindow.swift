//
//  MenuBarExtraWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import AppKit
import OSLog
import SpeakSwiftly
import SpeakSwiftlyServer
import SwiftUI

struct MenuBarExtraWindow: View {
    private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "menu-bar")

    @Environment(\.openSettings)
    private var openSettings

    @State
    private var isSubmittingClipboardSpeech = false

    @State
    private var isRunningVoiceAction = false

    @State
    private var isRunningBackendAction = false

    @State
    private var isRunningModelAction = false

    let server: EmbeddedServer
    let launchesEmbeddedRuntime: Bool

    private var status: MenuBarStatus {
        MenuBarStatus(
            launchesEmbeddedRuntime: launchesEmbeddedRuntime,
            recentErrorMessage: server.recentErrors.first?.message,
            startupError: server.overview.startupError,
            playbackState: server.playback.state,
            activePlaybackRequestID: server.playback.activeRequest?.id,
            workerStage: server.overview.workerStage,
            workerReady: server.overview.workerReady,
            serverMode: server.overview.serverMode
        )
    }

    private var queueSummary: MenuBarDisplaySupport.QueueSummary {
        MenuBarDisplaySupport.queueSummary(
            activeCount: server.generationQueue.activeCount,
            queuedCount: server.generationQueue.queuedCount
        )
    }

    private var selectedVoiceProfileName: String {
        server.overview.defaultVoiceProfileName ?? server.voiceProfiles.first?.profileName ?? ""
    }

    private var selectedBackend: SpeakSwiftly.SpeechBackend {
        SpeakSwiftly.SpeechBackend.normalized(
            rawValue: server.runtimeConfiguration.activeRuntimeSpeechBackend
        ) ?? .qwen3
    }

    private var powerSymbolName: String {
        server.overview.workerStage == "resident_models_unloaded" ? "power.circle" : "power.circle.fill"
    }

    private var playbackSymbolName: String {
        switch server.playback.state {
            case "playing":
                return "pause.fill"
            case "paused":
                return "play.fill"
            default:
                return "clipboard"
        }
    }

    // MARK: Main View Body

    var body: some View {
        let currentStatus = status

        VStack(alignment: .leading, spacing: 12) {
            MenuHeaderComponent(
                headline: currentStatus.headline,
                detail: currentStatus.detail
            )

            QueueCountComponent(
                summary: queueSummary,
                label: "Generation"
            )

            MenuControlGroupComponent(
                powerSymbolName: powerSymbolName,
                playbackSymbolName: playbackSymbolName,
                isPowerButtonDisabled: isRunningModelAction,
                isPlaybackButtonDisabled: isSubmittingClipboardSpeech,
                powerAction: toggleResidentModels,
                playbackAction: handlePlaybackButton,
                openSettingsAction: { openSettings() }
            )

            MenuPickerComponent(
                selectedVoiceProfileName: Binding(
                    get: { selectedVoiceProfileName },
                    set: { newValue in
                        handleVoiceSelection(newValue)
                    }
                ),
                selectedBackend: Binding(
                    get: { selectedBackend },
                    set: { newValue in
                        handleBackendSelection(newValue)
                    }
                ),
                voiceProfiles: server.voiceProfiles,
                availableBackends: SpeakSwiftly.SpeechBackend.allCases,
                isVoicePickerDisabled: server.voiceProfiles.isEmpty || isRunningVoiceAction,
                isBackendPickerDisabled: isRunningBackendAction
            )
        }
        .padding(14)
        .frame(width: 320)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-menu-window")
        .task {
            await refreshVoiceProfilesIfNeeded()
        }
    }
}

private extension MenuBarExtraWindow {
    @MainActor
    func refreshVoiceProfilesIfNeeded() async {
        guard server.voiceProfiles.isEmpty else {
            return
        }

        do {
            isRunningVoiceAction = true
            _ = try await MenuBarActionSupport.refreshVoiceProfilesIfNeeded(
                voiceProfilesAreEmpty: true,
                refreshVoiceProfiles: {
                    _ = try await server.refreshVoiceProfiles()
                }
            )
        } catch {
            handleActionError(
                error,
                fallbackMessage: "SayBar could not refresh the embedded voice profile list for the menu bar."
            )
        }

        isRunningVoiceAction = false
    }

    @MainActor
    func toggleResidentModels() {
        Task { @MainActor in
            isRunningModelAction = true
            do {
                switch MenuBarActionSupport.residentModelCommand(workerStage: server.overview.workerStage) {
                    case .reload:
                        _ = try await server.reloadModels()
                    case .unload:
                        _ = try await server.unloadModels()
                }
            } catch {
                handleActionError(
                    error,
                    fallbackMessage: "SayBar could not change the resident model state."
                )
            }
            isRunningModelAction = false
        }
    }

    @MainActor
    func handlePlaybackButton() {
        Task { @MainActor in
            switch MenuBarActionSupport.playbackCommand(playbackState: server.playback.state) {
                case .pause:
                    do {
                        _ = try await server.pausePlayback()
                    } catch {
                        handleActionError(
                            error,
                            fallbackMessage: "SayBar could not pause playback."
                        )
                    }
                case .resume:
                    do {
                        _ = try await server.resumePlayback()
                    } catch {
                        handleActionError(
                            error,
                            fallbackMessage: "SayBar could not resume playback."
                        )
                    }
                case .submitClipboardSpeech:
                    await submitClipboardSpeech()
            }
        }
    }

    @MainActor
    func submitClipboardSpeech() async {
        let clipboardText = NSPasteboard.general.string(forType: .string)
        guard !MenuBarActionSupport.normalizedClipboardText(clipboardText).isEmpty else {
            Self.logger.notice("SayBar ignored the clipboard speech action because the clipboard did not contain speakable text.")
            return
        }

        isSubmittingClipboardSpeech = true
        defer { isSubmittingClipboardSpeech = false }

        do {
            let result = try await MenuBarActionSupport.queueClipboardSpeech(
                clipboardText: clipboardText,
                queueLiveSpeech: { pastedText, requestContext in
                    _ = try await server.queueLiveSpeech(
                        text: pastedText,
                        requestContext: requestContext
                    )
                }
            )
            switch result {
                case .emptyClipboard:
                    Self.logger.notice("SayBar ignored the clipboard speech action because the clipboard did not contain speakable text after normalization.")
                case .queued:
                    break
            }
        } catch {
            handleActionError(
                error,
                fallbackMessage: "SayBar could not queue clipboard text for live speech."
            )
        }
    }

    @MainActor
    func handleVoiceSelection(_ profileName: String) {
        Task { @MainActor in
            isRunningVoiceAction = true
            do {
                if let resolvedProfileName = try await MenuBarActionSupport.setDefaultVoiceProfile(
                    profileName: profileName,
                    setDefaultVoiceProfileName: { profileName in
                        try await server.setDefaultVoiceProfileName(profileName)
                    }
                ) {
                    Self.logger.notice("SayBar set the embedded runtime default voice profile to '\(resolvedProfileName, privacy: .public)'.")
                }
            } catch {
                handleActionError(
                    error,
                    fallbackMessage: "SayBar could not set the default voice profile."
                )
            }
            isRunningVoiceAction = false
        }
    }

    @MainActor
    func handleBackendSelection(_ backend: SpeakSwiftly.SpeechBackend) {
        Task { @MainActor in
            isRunningBackendAction = true
            do {
                _ = try await MenuBarActionSupport.switchSpeechBackend(
                    to: backend,
                    switchSpeechBackend: { backend in
                        _ = try await server.switchSpeechBackend(to: backend)
                    }
                )
            } catch {
                handleActionError(
                    error,
                    fallbackMessage: "SayBar could not switch the active speech backend."
                )
            }
            isRunningBackendAction = false
        }
    }

    @MainActor
    func handleActionError(_ error: Error, fallbackMessage: String) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        Self.logger.error("\(fallbackMessage, privacy: .public) Likely cause: \(message, privacy: .public)")
    }
}

#Preview {
    MenuBarExtraWindow(
        server: EmbeddedServer(),
        launchesEmbeddedRuntime: false
    )
}
