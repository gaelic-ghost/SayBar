//
//  SettingsWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SpeakSwiftlyServer
import SwiftUI

struct SettingsWindow: View {
    let displayState: SettingsDisplayState

    @Binding
    var isMenuBarExtraInserted: Bool

    init(
        server: EmbeddedServer,
        autostartEnabled: Bool,
        isMenuBarExtraInserted: Binding<Bool>
    ) {
        displayState = SettingsDisplayState(
            server: server,
            autostartEnabled: autostartEnabled,
            buildVersion: Self.buildVersion
        )
        _isMenuBarExtraInserted = isMenuBarExtraInserted
    }

    init(
        displayState: SettingsDisplayState,
        isMenuBarExtraInserted: Binding<Bool>
    ) {
        self.displayState = displayState
        _isMenuBarExtraInserted = isMenuBarExtraInserted
    }

    private static var buildVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    var body: some View {
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
        autostartEnabled: false,
        isMenuBarExtraInserted: .constant(true)
    )
}
