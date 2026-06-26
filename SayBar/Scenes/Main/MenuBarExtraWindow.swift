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

    @State
    private var isRunningQueueAction = false

    @State
    private var pendingQueueConfirmation: QueueConfirmation?

    @State
    private var selectedSurface: MenuBarDisplaySupport.Surface

    @State
    private var surfaceTransitionEdge: Edge = .trailing

    let server: EmbeddedServer
    let launchesEmbeddedRuntime: Bool

    init(
        server: EmbeddedServer,
        launchesEmbeddedRuntime: Bool,
        initialSurface: MenuBarDisplaySupport.Surface = .primary
    ) {
        self.server = server
        self.launchesEmbeddedRuntime = launchesEmbeddedRuntime
        _selectedSurface = State(initialValue: initialSurface)
    }

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

    private var playbackQueueSummary: MenuBarDisplaySupport.QueueSummary {
        MenuBarDisplaySupport.queueSummary(
            activeCount: server.playbackQueue.activeCount,
            queuedCount: server.playbackQueue.queuedCount,
            capacity: 12
        )
    }

    private var selectedVoiceProfileName: String {
        server.overview.defaultVoiceProfileName ?? server.voiceProfiles.first?.profileName ?? ""
    }

    private var selectedBackend: SpeakSwiftly.SpeechBackend {
        SpeakSwiftly.SpeechBackend.normalized(
            rawValue: server.runtimeConfiguration.activeRuntimeSpeechBackend
        ) ?? .qwen3_smol
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
        ZStack(alignment: .leading) {
            surfaceView
                .id(selectedSurface)
                .transition(surfaceTransition)
        }
        .padding(14)
        .frame(width: 320)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-menu-window")
        .overlay {
            HorizontalSwipeGestureMonitor { direction in
                navigateMenuSurface(direction)
            }
        }
        .task {
            await refreshVoiceProfilesIfNeeded()
        }
    }
}

private extension MenuBarExtraWindow {
    enum QueueConfirmation {
        case clearPlaybackQueue
    }

    @ViewBuilder
    var surfaceView: some View {
        switch selectedSurface {
            case .queues:
                queuesSurface
            case .primary:
                primarySurface
            case .quickConfig:
                quickConfigSurface
        }
    }

    var primarySurface: some View {
        let currentStatus = status

        return VStack(alignment: .leading, spacing: 12) {
            MenuHeaderComponent(
                headline: currentStatus.headline,
                detail: currentStatus.detail
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
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MenuBarDisplaySupport.Surface.primary.accessibilityIdentifier)
    }

    var queuesSurface: some View {
        VStack(alignment: .leading, spacing: 12) {
            MenuPageHeaderComponent(title: "Queues", systemImage: "list.bullet.rectangle")
                .accessibilityIdentifier(MenuBarDisplaySupport.Surface.queues.accessibilityIdentifier)

            if let handoffRequestID = queueHandoffRequestID {
                HStack {
                    Spacer(minLength: 0)
                    QueueHandoffComponent(requestID: handoffRequestID)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer(minLength: 0)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                QueuePanelComponent(
                    title: "Generation",
                    systemImage: "waveform",
                    summary: queueSummary,
                    accessibilityIDPrefix: "generation",
                    activeRequests: server.generationQueue.activeRequests,
                    queuedRequests: server.generationQueue.queuedRequests,
                    clearAction: nil,
                    cancelActiveAction: nil,
                    isClearDisabled: true,
                    isCancelActiveDisabled: true
                )

                QueuePanelComponent(
                    title: "Playback",
                    systemImage: "speaker.wave.2",
                    summary: playbackQueueSummary,
                    accessibilityIDPrefix: "playback",
                    activeRequests: server.playbackQueue.activeRequests,
                    queuedRequests: server.playbackQueue.queuedRequests,
                    clearAction: requestPlaybackQueueClearConfirmation,
                    cancelActiveAction: cancelActivePlaybackRequest,
                    isClearDisabled: isRunningQueueAction || server.playbackQueue.queuedCount <= 0,
                    isCancelActiveDisabled: isRunningQueueAction || activePlaybackRequestID == nil
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MenuBarDisplaySupport.Surface.queues.accessibilityIdentifier)
        .confirmationDialog(
            "Clear Playback Queue?",
            isPresented: playbackQueueClearConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Clear Playback Queue", role: .destructive) {
                clearPlaybackQueue()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Queued playback requests will be removed. Active playback is not canceled.")
        }
    }

    var quickConfigSurface: some View {
        MenuQuickConfigSurfaceComponent(
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
        .accessibilityIdentifier(MenuBarDisplaySupport.Surface.quickConfig.accessibilityIdentifier)
    }

    var surfaceTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: surfaceTransitionEdge).combined(with: .opacity),
            removal: .move(edge: surfaceTransitionEdge == .leading ? .trailing : .leading).combined(with: .opacity)
        )
    }

    var queueHandoffRequestID: String? {
        let activePlaybackRequestIDs = Set(server.playbackQueue.activeRequests.map(\.id))
        return server.generationQueue.activeRequests.first { request in
            activePlaybackRequestIDs.contains(request.id)
        }?.id
    }

    var activePlaybackRequestID: String? {
        server.playbackQueue.activeRequests.first?.id ?? server.playback.activeRequest?.id
    }

    var playbackQueueClearConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingQueueConfirmation == .clearPlaybackQueue },
            set: { isPresented in
                if !isPresented {
                    pendingQueueConfirmation = nil
                }
            }
        )
    }

    @MainActor
    func navigateMenuSurface(_ direction: MenuBarDisplaySupport.SurfaceNavigationDirection) {
        let nextSurface = MenuBarDisplaySupport.navigatedSurface(
            from: selectedSurface,
            direction: direction
        )
        guard nextSurface != selectedSurface else {
            return
        }

        surfaceTransitionEdge = direction == .previous ? .leading : .trailing
        withAnimation(.snappy(duration: 0.22)) {
            selectedSurface = nextSurface
        }
    }

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
    func requestPlaybackQueueClearConfirmation() {
        pendingQueueConfirmation = .clearPlaybackQueue
    }

    @MainActor
    func clearPlaybackQueue() {
        pendingQueueConfirmation = nil
        Task { @MainActor in
            isRunningQueueAction = true
            defer { isRunningQueueAction = false }

            do {
                let result = try await MenuBarActionSupport.clearPlaybackQueue(
                    queuedCount: server.playbackQueue.queuedCount,
                    clearPlaybackQueue: {
                        try await server.clearPlaybackQueue()
                    }
                )
                switch result {
                    case .cleared(let clearedCount):
                        Self.logger.notice("SayBar cleared \(clearedCount, privacy: .public) queued playback request(s).")
                    case .skipped:
                        Self.logger.notice("SayBar skipped clearing the playback queue because no queued playback requests were visible.")
                    case .canceled:
                        break
                }
            } catch {
                handleActionError(
                    error,
                    fallbackMessage: "SayBar could not clear the queued playback requests."
                )
            }
        }
    }

    @MainActor
    func cancelActivePlaybackRequest() {
        Task { @MainActor in
            isRunningQueueAction = true
            defer { isRunningQueueAction = false }

            do {
                let result = try await MenuBarActionSupport.cancelPlaybackRequest(
                    requestID: activePlaybackRequestID,
                    cancelPlaybackRequest: { requestID in
                        try await server.cancelPlaybackRequest(requestID)
                    }
                )
                switch result {
                    case .canceled(let requestID):
                        Self.logger.notice("SayBar canceled active playback request '\(requestID, privacy: .public)'.")
                    case .skipped:
                        Self.logger.notice("SayBar skipped canceling active playback because no active playback request was visible.")
                    case .cleared:
                        break
                }
            } catch {
                handleActionError(
                    error,
                    fallbackMessage: "SayBar could not cancel the active playback request."
                )
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
