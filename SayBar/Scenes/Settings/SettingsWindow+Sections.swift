//
//  SettingsWindow+Sections.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SpeakSwiftlyServer
import SwiftUI

struct SettingsAppInfoSection: View {
    let buildVersion: String
    let autostartEnabled: Bool

    @Binding
    var isMenuBarExtraInserted: Bool

    var body: some View {
        Section("App") {
            LabeledContent("Version", value: buildVersion)
            LabeledContent("Embedded Autostart", value: autostartEnabled ? "Enabled" : "Disabled")
            Toggle("Show Menu Bar Extra", isOn: $isMenuBarExtraInserted)
        }
    }
}

struct SettingsRuntimeOverviewSection: View {
    let server: EmbeddedServer

    var body: some View {
        Section("Runtime") {
            LabeledContent("Status", value: server.overview.serverMode)
            LabeledContent("Worker Stage", value: server.overview.workerStage)
            LabeledContent("Playback", value: server.playback.state)
            LabeledContent("Speech Backend", value: server.runtimeConfiguration.activeRuntimeSpeechBackend)
            LabeledContent("Default Voice Profile", value: server.overview.defaultVoiceProfileName ?? "None")
            LabeledContent("Generation Queue", value: "\(server.generationQueue.activeCount + server.generationQueue.queuedCount)")
            LabeledContent("Playback Queue", value: "\(server.playbackQueue.activeCount + server.playbackQueue.queuedCount)")
        }
    }
}

struct SettingsTransportDiagnosticsSection: View {
    let transports: [TransportStatusSnapshot]

    var body: some View {
        Section("Transports") {
            if transports.isEmpty {
                Text("No operator transports are published yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(transports.enumerated()), id: \.offset) { _, transport in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transport.name)
                            .font(.headline)
                        Text(transportSummary(transport))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func transportSummary(_ transport: TransportStatusSnapshot) -> String {
        SettingsDisplaySupport.transportSummary(
            state: transport.state,
            host: transport.host,
            port: transport.port,
            path: transport.path
        )
    }
}

struct SettingsRecentErrorsSection: View {
    let recentErrors: [RecentErrorSnapshot]

    var body: some View {
        Section("Recent Errors") {
            if recentErrors.isEmpty {
                Text("No recent runtime or transport errors are retained.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(recentErrors.enumerated()), id: \.offset) { _, error in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.source)
                            .font(.headline)
                        Text(error.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
