//
//  SettingsWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SpeakSwiftlyServer
import SwiftUI

struct SettingsWindow: View {
    let server: EmbeddedServer
    let autostartEnabled: Bool

    @Binding
    var isMenuBarExtraInserted: Bool

    private var buildVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            SettingsAppInfoSection(
                buildVersion: buildVersion,
                autostartEnabled: autostartEnabled,
                isMenuBarExtraInserted: $isMenuBarExtraInserted
            )

            SettingsRuntimeOverviewSection(server: server)

            SettingsTransportDiagnosticsSection(transports: server.transports)

            SettingsRecentErrorsSection(recentErrors: server.recentErrors)
        }
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
