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
                .accessibilityIdentifier("saybar-settings-version")
            LabeledContent("Embedded Autostart", value: SettingsDisplaySupport.enabledStatus(autostartEnabled))
                .accessibilityIdentifier("saybar-settings-embedded-autostart")
            Toggle("Show Menu Bar Extra", isOn: $isMenuBarExtraInserted)
                .accessibilityIdentifier("saybar-settings-menu-bar-extra-toggle")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-app-section")
    }
}

struct SettingsRuntimeOverviewSection: View {
    let server: EmbeddedServer

    var body: some View {
        Section("Runtime") {
            LabeledContent("Status", value: server.overview.serverMode)
                .accessibilityIdentifier("saybar-settings-runtime-status")
            LabeledContent("Worker Stage", value: server.overview.workerStage)
                .accessibilityIdentifier("saybar-settings-worker-stage")
            LabeledContent("Playback", value: server.playback.state)
                .accessibilityIdentifier("saybar-settings-playback-state")
            LabeledContent("Speech Backend", value: server.runtimeConfiguration.activeRuntimeSpeechBackend)
                .accessibilityIdentifier("saybar-settings-speech-backend")
            LabeledContent(
                "Default Voice Profile",
                value: SettingsDisplaySupport.defaultVoiceProfileName(server.overview.defaultVoiceProfileName)
            )
            .accessibilityIdentifier("saybar-settings-default-voice-profile")
            LabeledContent(
                "Generation Queue",
                value: SettingsDisplaySupport.queueCount(
                    activeCount: server.generationQueue.activeCount,
                    queuedCount: server.generationQueue.queuedCount
                )
            )
            .accessibilityIdentifier("saybar-settings-generation-queue")
            LabeledContent(
                "Playback Queue",
                value: SettingsDisplaySupport.queueCount(
                    activeCount: server.playbackQueue.activeCount,
                    queuedCount: server.playbackQueue.queuedCount
                )
            )
            .accessibilityIdentifier("saybar-settings-playback-queue")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-runtime-section")
    }
}

struct SettingsTransportDiagnosticsSection: View {
    let transports: [TransportStatusSnapshot]

    var body: some View {
        Section("Transports") {
            if transports.isEmpty {
                Text("No operator transports are published yet.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("saybar-settings-empty-transports")
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
                    .accessibilityIdentifier("saybar-settings-transport-row-\(transport.name)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-transports-section")
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
                    .accessibilityIdentifier("saybar-settings-empty-recent-errors")
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
                    .accessibilityIdentifier("saybar-settings-recent-error-row-\(error.source)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-recent-errors-section")
    }
}
