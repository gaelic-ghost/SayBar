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
    var isMenuBarExtraInserted: Bool

    var body: some View {
        Section("App") {
            LabeledContent("Version", value: appInfo.buildVersion)
                .accessibilityIdentifier("saybar-settings-version")
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

struct SettingsDetailRowsSection: View {
    let title: String
    let rows: [SettingsDisplayState.DetailRow]

    var body: some View {
        Section(title) {
            if rows.isEmpty {
                Text("No diagnostics are published yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rows) { row in
                    LabeledContent(row.label, value: row.value)
                        .accessibilityIdentifier("saybar-settings-detail-\(row.id)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-\(title.normalizedAccessibilityID)-section")
    }
}

struct SettingsQueueDiagnosticsSection: View {
    let queues: [SettingsDisplayState.QueueDiagnostics]

    var body: some View {
        Section("Queues") {
            if queues.isEmpty {
                Text("No queue diagnostics are published yet.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("saybar-settings-empty-queues")
            } else {
                ForEach(queues) { queue in
                    VStack(alignment: .leading, spacing: 6) {
                        LabeledContent(queue.title, value: queue.summary)
                            .accessibilityIdentifier("saybar-settings-queue-\(queue.id)")

                        ForEach(queue.activeRequests) { request in
                            SettingsRequestRow(request: request)
                        }

                        ForEach(queue.queuedRequests) { request in
                            SettingsRequestRow(request: request)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-queues-section")
    }
}

private struct SettingsRequestRow: View {
    let request: SettingsDisplayState.RequestRow

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(request.state) \(request.operation)")
                .font(.caption.weight(.semibold))
            Text("\(request.profileName) - \(request.id)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("saybar-settings-request-row-\(request.id)")
    }
}

struct SettingsGenerationJobsSection: View {
    let jobs: [SettingsDisplayState.GenerationJobRow]

    var body: some View {
        Section("Generation Jobs") {
            if jobs.isEmpty {
                Text("No generation jobs are active.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("saybar-settings-empty-generation-jobs")
            } else {
                ForEach(jobs) { job in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(job.operation)
                            .font(.caption.weight(.semibold))
                        Text("\(job.profileName) - \(job.latestStage) - \(job.elapsed)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("saybar-settings-generation-job-\(job.id)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-generation-jobs-section")
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
                        LabeledContent("Enabled", value: transport.enabled)
                            .font(.caption)
                            .accessibilityIdentifier("saybar-settings-transport-\(transport.name)-enabled")
                        LabeledContent("Advertised Address", value: transport.advertisedAddress)
                            .font(.caption)
                            .accessibilityIdentifier("saybar-settings-transport-\(transport.name)-advertised-address")
                        LabeledContent("Active Streams", value: transport.activeStreamCount)
                            .font(.caption)
                            .accessibilityIdentifier("saybar-settings-transport-\(transport.name)-active-streams")
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

struct SettingsNetworkAudioSection: View {
    let receiverDiagnostics: [SettingsDisplayState.DetailRow]
    let destinations: [SettingsDisplayState.NetworkAudioDestinationRow]

    var body: some View {
        Section("Network Audio") {
            ForEach(receiverDiagnostics) { row in
                LabeledContent(row.label, value: row.value)
                    .accessibilityIdentifier("saybar-settings-network-audio-\(row.id)")
            }

            if destinations.isEmpty {
                Text("No LAN audio receivers are visible.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("saybar-settings-empty-network-audio-destinations")
            } else {
                ForEach(destinations) { destination in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destination.name)
                            .font(.headline)
                        Text(destination.endpoint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(destination.capabilities)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        LabeledContent("Last Seen", value: destination.lastSeen)
                            .font(.caption)
                            .accessibilityIdentifier("saybar-settings-network-audio-destination-\(destination.id)-last-seen")
                    }
                    .padding(.vertical, 2)
                    .accessibilityIdentifier("saybar-settings-network-audio-destination-\(destination.id)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-settings-network-audio-section")
    }
}

private extension String {
    var normalizedAccessibilityID: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "-")
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
                        Text("\(error.code) at \(error.occurredAt)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
