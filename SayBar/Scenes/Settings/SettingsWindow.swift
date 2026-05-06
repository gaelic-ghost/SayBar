//
//  SettingsWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SpeakSwiftlyServer
import SwiftUI

struct SettingsWindow: View {
    private enum Source {
        case server(EmbeddedServer)
        case fixture(SettingsDisplayState)
    }

    private let source: Source

    @Binding
    var isMenuBarExtraInserted: Bool

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

        Form {
            SettingsAppInfoSection(
                appInfo: displayState.appInfo,
                isMenuBarExtraInserted: $isMenuBarExtraInserted
            )

            SettingsRuntimeOverviewSection(runtimeOverview: displayState.runtimeOverview)

            SettingsTransportDiagnosticsSection(transports: displayState.transports)

            SettingsRecentErrorsSection(recentErrors: displayState.recentErrors)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-window")
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 420, idealWidth: 480, minHeight: 340)
    }
}

#Preview {
    SettingsWindow(
        server: EmbeddedServer(),
        isMenuBarExtraInserted: .constant(true)
    )
}
