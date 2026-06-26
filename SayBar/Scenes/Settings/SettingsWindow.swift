//
//  SettingsWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import OSLog
import SpeakSwiftlyServer
import SwiftUI

struct SettingsWindow: View {
    private enum SettingsTab: Hashable {
        case primary
        case queues
        case diagnostics
    }

    private enum QueueConfirmation {
        case clearPlaybackQueue
    }

    private enum Source {
        case server(EmbeddedServer)
        case fixture(SettingsDisplayState)
    }

    private let source: Source

    @Binding
    var isMenuBarExtraInserted: Bool

    @State
    private var selectedTab: SettingsTab = .primary

    @State
    private var isRunningQueueAction = false

    @State
    private var pendingQueueConfirmation: QueueConfirmation?

    init(
        server: EmbeddedServer,
        isMenuBarExtraInserted: Binding<Bool>
    ) {
        source = .server(server)
        _isMenuBarExtraInserted = isMenuBarExtraInserted
    }

    init(
        displayState: SettingsDisplayState,
        isMenuBarExtraInserted: Binding<Bool>
    ) {
        source = .fixture(displayState)
        _isMenuBarExtraInserted = isMenuBarExtraInserted
    }

    private static var buildVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private var displayState: SettingsDisplayState {
        switch source {
            case .server(let server):
                SettingsDisplayState(
                    server: server,
                    buildVersion: Self.buildVersion
                )
            case .fixture(let displayState):
                displayState
        }
    }

    private var embeddedServer: EmbeddedServer? {
        switch source {
            case .server(let server):
                return server
            case .fixture:
                return nil
        }
    }

    var body: some View {
        let displayState = displayState

        TabView(selection: $selectedTab) {
            primaryTab(displayState)
            queuesTab(displayState)
            diagnosticsTab(displayState)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-window")
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
        .frame(minWidth: 460, idealWidth: 560, minHeight: 420)
    }
}

private extension SettingsWindow {
    var playbackQueueClearAction: (() -> Void)? {
        guard embeddedServer != nil else {
            return nil
        }

        return {
            requestPlaybackQueueClearConfirmation()
        }
    }

    var playbackRequestCancelAction: ((String) -> Void)? {
        guard embeddedServer != nil else {
            return nil
        }

        return { requestID in
            cancelPlaybackRequest(requestID)
        }
    }

    func primaryTab(_ displayState: SettingsDisplayState) -> some View {
        Form {
            SettingsAppInfoSection(
                appInfo: displayState.appInfo,
                isMenuBarExtraInserted: $isMenuBarExtraInserted
            )

            SettingsRuntimeOverviewSection(runtimeOverview: displayState.runtimeOverview)
        }
        .formStyle(.grouped)
        .padding()
        .tabItem {
            Label("Primary", systemImage: "slider.horizontal.below.rectangle")
        }
        .tag(SettingsTab.primary)
        .accessibilityIdentifier("saybar-settings-primary-tab")
    }

    func queuesTab(_ displayState: SettingsDisplayState) -> some View {
        SettingsQueuesTabContent(
            queues: displayState.queues,
            clearPlaybackQueue: playbackQueueClearAction,
            cancelPlaybackRequest: playbackRequestCancelAction,
            isRunningQueueAction: isRunningQueueAction
        )
        .tabItem {
            Label("Queues", systemImage: "list.bullet.rectangle")
        }
        .tag(SettingsTab.queues)
    }

    func diagnosticsTab(_ displayState: SettingsDisplayState) -> some View {
        Form {
            SettingsDetailRowsSection(
                title: "Runtime Details",
                rows: displayState.runtimeDiagnostics
            )

            SettingsDetailRowsSection(
                title: "Playback Details",
                rows: displayState.playbackDiagnostics
            )

            SettingsDetailRowsSection(
                title: "Configuration Details",
                rows: displayState.configurationDiagnostics
            )

            SettingsGenerationJobsSection(jobs: displayState.generationJobs)

            SettingsTransportDiagnosticsSection(transports: displayState.transports)

            SettingsNetworkAudioSection(
                receiverDiagnostics: displayState.networkAudioReceiverDiagnostics,
                destinations: displayState.networkAudioDestinations
            )

            SettingsRecentErrorsSection(recentErrors: displayState.recentErrors)
        }
        .formStyle(.grouped)
        .padding()
        .tabItem {
            Label("Diagnostics", systemImage: "waveform.path.ecg.rectangle")
        }
        .tag(SettingsTab.diagnostics)
        .accessibilityIdentifier("saybar-settings-diagnostics-tab")
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
    func requestPlaybackQueueClearConfirmation() {
        pendingQueueConfirmation = .clearPlaybackQueue
    }

    @MainActor
    func clearPlaybackQueue() {
        pendingQueueConfirmation = nil
        guard let embeddedServer else {
            return
        }

        Task { @MainActor in
            isRunningQueueAction = true
            defer { isRunningQueueAction = false }

            do {
                _ = try await MenuBarActionSupport.clearPlaybackQueue(
                    queuedCount: embeddedServer.playbackQueue.queuedCount,
                    clearPlaybackQueue: {
                        try await embeddedServer.clearPlaybackQueue()
                    }
                )
            } catch {
                SettingsWindowLog.queueActionError(
                    error,
                    fallbackMessage: "SayBar Settings could not clear the queued playback requests."
                )
            }
        }
    }

    @MainActor
    func cancelPlaybackRequest(_ requestID: String) {
        guard let embeddedServer else {
            return
        }

        Task { @MainActor in
            isRunningQueueAction = true
            defer { isRunningQueueAction = false }

            do {
                _ = try await MenuBarActionSupport.cancelPlaybackRequest(
                    requestID: requestID,
                    cancelPlaybackRequest: { requestID in
                        try await embeddedServer.cancelPlaybackRequest(requestID)
                    }
                )
            } catch {
                SettingsWindowLog.queueActionError(
                    error,
                    fallbackMessage: "SayBar Settings could not cancel the selected playback request."
                )
            }
        }
    }
}

private enum SettingsWindowLog {
    private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "settings")

    static func queueActionError(_ error: Error, fallbackMessage: String) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        logger.error("\(fallbackMessage, privacy: .public) Likely cause: \(message, privacy: .public)")
    }
}

#Preview {
    SettingsWindow(
        server: EmbeddedServer(),
        isMenuBarExtraInserted: .constant(true)
    )
}
