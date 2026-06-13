//
//  SettingsWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SpeakSwiftlyServer
import SwiftUI

struct SettingsWindow: View {
    private enum SettingsTab: Hashable {
        case primary
        case diagnostics
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

    var body: some View {
        let displayState = displayState

        TabView(selection: $selectedTab) {
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

                SettingsQueueDiagnosticsSection(queues: displayState.queues)

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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-window")
        .frame(minWidth: 460, idealWidth: 560, minHeight: 420)
    }
}

#Preview {
    SettingsWindow(
        server: EmbeddedServer(),
        isMenuBarExtraInserted: .constant(true)
    )
}
