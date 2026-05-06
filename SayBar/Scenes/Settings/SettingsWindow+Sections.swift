//
//  SettingsWindow+Sections.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI

struct SettingsAppInfoSection: View {
    let appInfo: SettingsDisplayState.AppInfo

    @Binding
    var embeddedRuntimeAutostartEnabled: Bool

    @Binding
    var isMenuBarExtraInserted: Bool

    var body: some View {
        Section("App") {
            LabeledContent("Version", value: appInfo.buildVersion)
                .accessibilityIdentifier("saybar-settings-version")
            Toggle("Start Embedded Runtime on Launch", isOn: $embeddedRuntimeAutostartEnabled)
                .accessibilityIdentifier("saybar-settings-embedded-autostart")
            Toggle("Show Menu Bar Extra", isOn: $isMenuBarExtraInserted)
                .accessibilityIdentifier("saybar-settings-menu-bar-extra-toggle")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-app-section")
    }
}

struct SettingsRuntimeOverviewSection: View {
    let runtimeOverview: SettingsDisplayState.RuntimeOverview

    var body: some View {
        Section("Runtime") {
            LabeledContent("Status", value: runtimeOverview.status)
                .accessibilityIdentifier("saybar-settings-runtime-status")
            LabeledContent("Worker Stage", value: runtimeOverview.workerStage)
                .accessibilityIdentifier("saybar-settings-worker-stage")
            LabeledContent("Playback", value: runtimeOverview.playbackState)
                .accessibilityIdentifier("saybar-settings-playback-state")
            LabeledContent("Speech Backend", value: runtimeOverview.speechBackend)
                .accessibilityIdentifier("saybar-settings-speech-backend")
            LabeledContent(
                "Default Voice Profile",
                value: runtimeOverview.defaultVoiceProfileName
            )
            .accessibilityIdentifier("saybar-settings-default-voice-profile")
            LabeledContent(
                "Generation Queue",
                value: runtimeOverview.generationQueueCount
            )
            .accessibilityIdentifier("saybar-settings-generation-queue")
            LabeledContent(
                "Playback Queue",
                value: runtimeOverview.playbackQueueCount
            )
            .accessibilityIdentifier("saybar-settings-playback-queue")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-runtime-section")
    }
}

struct SettingsTransportDiagnosticsSection: View {
    let transports: [SettingsDisplayState.TransportRow]

    var body: some View {
        Section("Transports") {
            if transports.isEmpty {
                Text("No operator transports are published yet.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("saybar-settings-empty-transports")
            } else {
                ForEach(transports) { transport in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transport.name)
                            .font(.headline)
                        Text(transport.summary)
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
}

struct SettingsRecentErrorsSection: View {
    let recentErrors: [SettingsDisplayState.RecentErrorRow]

    var body: some View {
        Section("Recent Errors") {
            if recentErrors.isEmpty {
                Text("No recent runtime or transport errors are retained.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("saybar-settings-empty-recent-errors")
            } else {
                ForEach(recentErrors) { error in
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
