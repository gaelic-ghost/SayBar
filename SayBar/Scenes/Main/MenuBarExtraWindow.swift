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
    private var actionMessage: String?

    @State
    private var isSubmittingClipboardSpeech = false

    @State
    private var isRunningVoiceAction = false

    @State
    private var isRunningBackendAction = false

    @State
    private var isRunningModelAction = false

    let server: EmbeddedServer
    let autostartEnabled: Bool

    private var statusHeadline: String {
        MenuBarDisplaySupport.statusHeadline(
            autostartEnabled: autostartEnabled,
            recentErrorMessage: server.recentErrors.first?.message,
            startupError: server.overview.startupError,
            playbackState: server.playback.state,
            workerStage: server.overview.workerStage,
            serverMode: server.overview.serverMode
        )
    }

    private var statusDetail: String {
        MenuBarDisplaySupport.statusDetail(
            autostartEnabled: autostartEnabled,
            actionMessage: actionMessage,
            recentErrorMessage: server.recentErrors.first?.message,
            startupError: server.overview.startupError,
            playbackState: server.playback.state,
            activePlaybackRequestID: server.playback.activeRequest?.id,
            workerStage: server.overview.workerStage,
            workerReady: server.overview.workerReady,
            serverMode: server.overview.serverMode
        )
    }

    private var queueSlotCount: Int {
        MenuBarDisplaySupport.queueSlotCount(
            activeCount: server.generationQueue.activeCount,
            queuedCount: server.generationQueue.queuedCount
        )
    }

    private var selectedVoiceProfileName: String {
        MenuBarDisplaySupport.selectedVoiceProfileName(
            defaultVoiceProfileName: server.overview.defaultVoiceProfileName,
            firstProfileName: server.voiceProfiles.first?.profileName
        )
    }

    private var selectedBackend: SpeakSwiftly.SpeechBackend {
        SpeakSwiftly.SpeechBackend.normalized(
            rawValue: server.runtimeConfiguration.activeRuntimeSpeechBackend
        ) ?? .qwen3
    }

    private var powerSymbolName: String {
        MenuBarDisplaySupport.powerSymbolName(workerStage: server.overview.workerStage)
    }

    private var playbackSymbolName: String {
        MenuBarDisplaySupport.playbackSymbolName(playbackState: server.playback.state)
    }

    // MARK: Main View Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MenuHeaderComponent(
                headline: statusHeadline,
                detail: statusDetail
            )

            QueueCountComponent(
                filledSlotCount: queueSlotCount,
                totalSlotCount: 8,
                label: "Queue"
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
                        actionMessage = "Resident models are loaded again."
                    case .unload:
                        _ = try await server.unloadModels()
                        actionMessage = "Resident models are unloaded."
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
                        actionMessage = "Playback is paused."
                    } catch {
                        handleActionError(
                            error,
                            fallbackMessage: "SayBar could not pause playback."
                        )
                    }
                case .resume:
                    do {
                        _ = try await server.resumePlayback()
                        actionMessage = "Playback resumed."
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
            actionMessage = "The clipboard does not contain text to speak."
            return
        }

        isSubmittingClipboardSpeech = true
        defer { isSubmittingClipboardSpeech = false }

        do {
            let result = try await MenuBarActionSupport.queueClipboardSpeech(
                clipboardText: clipboardText,
                queueLiveSpeech: { pastedText in
                    _ = try await server.queueLiveSpeech(text: pastedText)
                }
            )
            switch result {
                case .emptyClipboard:
                    actionMessage = "The clipboard does not contain text to speak."
                case .queued:
                    actionMessage = "Queued clipboard text for live speech."
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
                    actionMessage = "Default voice profile set to \(resolvedProfileName)."
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
                let backendName = try await MenuBarActionSupport.switchSpeechBackend(
                    to: backend,
                    switchSpeechBackend: { backend in
                        _ = try await server.switchSpeechBackend(to: backend)
                    }
                )
                actionMessage = "Speech backend switched to \(backendName)."
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
        actionMessage = message.isEmpty ? fallbackMessage : message
        Self.logger.error("\(fallbackMessage, privacy: .public) Likely cause: \(message, privacy: .public)")
    }
}

#Preview {
    MenuBarExtraWindow(
        server: EmbeddedServer(),
        autostartEnabled: false
    )
}
