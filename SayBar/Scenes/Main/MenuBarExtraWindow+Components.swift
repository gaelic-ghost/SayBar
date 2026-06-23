//
//  MenuBarExtraWindow+Components.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SpeakSwiftly
import SpeakSwiftlyServer
import SwiftUI

struct MenuHeaderComponent: View {
    let headline: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headline)
                .font(.headline)
                .accessibilityIdentifier("saybar-status-headline")
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("saybar-status-detail")
        }
        .accessibilityElement(children: .contain)
    }
}

struct QueueCountComponent: View {
    let summary: MenuBarDisplaySupport.QueueSummary
    let label: String
    let accessibilityIDPrefix: String
    var slotWidth: CGFloat = 8
    var slotHeight: CGFloat = 18
    var slotSpacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label): \(summary.activeCount) active, \(summary.queuedCount) queued / \(summary.capacity)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("saybar-\(accessibilityIDPrefix)-queue-summary")
            HStack(alignment: .center, spacing: slotSpacing) {
                ForEach(0..<summary.capacity, id: \.self) { index in
                    QueueSlotShape(
                        state: slotState(at: index),
                        width: slotWidth,
                        height: slotHeight
                    )
                }
            }
            .accessibilityIdentifier("saybar-\(accessibilityIDPrefix)-queue-slots")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-\(accessibilityIDPrefix)-queue")
    }

    private func slotState(at index: Int) -> QueueSlotShape.State {
        if index < summary.visibleActiveSlotCount {
            return .active
        }
        if index < summary.visibleActiveSlotCount + summary.visibleQueuedSlotCount {
            return .queued
        }
        return .empty
    }
}

struct QueuePanelComponent: View {
    let title: String
    let systemImage: String
    let summary: MenuBarDisplaySupport.QueueSummary
    let accessibilityIDPrefix: String
    let activeRequests: [ActiveRequestSnapshot]
    let queuedRequests: [QueuedRequestSnapshot]
    let clearAction: (() -> Void)?
    let cancelActiveAction: (() -> Void)?
    let isClearDisabled: Bool
    let isCancelActiveDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            QueueCountComponent(
                summary: summary,
                label: title,
                accessibilityIDPrefix: accessibilityIDPrefix,
                slotWidth: 4,
                slotHeight: 14,
                slotSpacing: 1.5
            )

            if clearAction != nil || cancelActiveAction != nil {
                HStack(spacing: 6) {
                    if let cancelActiveAction {
                        Button(action: cancelActiveAction) {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCancelActiveDisabled)
                        .help("Cancel active playback request")
                        .accessibilityLabel("Cancel Active Playback Request")
                        .accessibilityIdentifier("saybar-\(accessibilityIDPrefix)-cancel-active-request")
                    }

                    if let clearAction {
                        Button(role: .destructive, action: clearAction) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isClearDisabled)
                        .help("Clear queued playback requests")
                        .accessibilityLabel("Clear Playback Queue")
                        .accessibilityIdentifier("saybar-\(accessibilityIDPrefix)-clear-queue")
                    }
                }
            }

            QueueRequestListComponent(
                title: "Requests",
                activeRequests: activeRequests,
                queuedRequests: queuedRequests
            )
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-\(accessibilityIDPrefix)-queue-panel")
    }
}

struct QueueHandoffComponent: View {
    let requestID: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .imageScale(.small)
            Text("Generation to playback")
                .font(.caption.weight(.semibold))
            Text(requestID)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("saybar-queue-handoff")
    }
}

struct QueueRequestListComponent: View {
    let title: String
    let activeRequests: [ActiveRequestSnapshot]
    let queuedRequests: [QueuedRequestSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if activeRequests.isEmpty && queuedRequests.isEmpty {
                Text("Idle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeRequests, id: \.id) { request in
                    RequestRowComponent(
                        state: "Active",
                        id: request.id,
                        operation: request.op,
                        profileName: request.profileName
                    )
                }

                ForEach(queuedRequests, id: \.id) { request in
                    RequestRowComponent(
                        state: "#\(request.queuePosition)",
                        id: request.id,
                        operation: request.op,
                        profileName: request.profileName
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct RequestRowComponent: View {
    let state: String
    let id: String
    let operation: String
    let profileName: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(state)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(operation)
                    .font(.caption)
                    .lineLimit(1)
                Text(profileName.map { "\($0) - \(id)" } ?? id)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct QueueSlotShape: View {
    enum State {
        case active
        case queued
        case empty
    }

    let state: State
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Rectangle()
            .fill(fillColor)
            .overlay {
                Rectangle()
                    .stroke(strokeColor, lineWidth: 1)
            }
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }

    private var fillColor: Color {
        switch state {
            case .active:
                return .accentColor
            case .queued:
                return .secondary.opacity(0.65)
            case .empty:
                return .clear
        }
    }

    private var strokeColor: Color {
        switch state {
            case .active:
                return .accentColor
            case .queued:
                return .secondary.opacity(0.75)
            case .empty:
                return .secondary.opacity(0.25)
        }
    }
}

struct MenuPageHeaderComponent: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .imageScale(.small)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct MenuControlGroupComponent: View {
    let powerSymbolName: String
    let playbackSymbolName: String
    let isPowerButtonDisabled: Bool
    let isPlaybackButtonDisabled: Bool
    let powerAction: () -> Void
    let playbackAction: () -> Void
    let openSettingsAction: () -> Void

    var body: some View {
        ControlGroup {
            HStack(alignment: .center, spacing: 20) {
                Button(action: powerAction) {
                    Image(systemName: powerSymbolName)
                }
                .disabled(isPowerButtonDisabled)
                .buttonStyle(.bordered)
                .accessibilityLabel("Resident Model Power")
                .accessibilityIdentifier("saybar-resident-model-power")

                Button(action: playbackAction) {
                    Image(systemName: playbackSymbolName)
                }
                .disabled(isPlaybackButtonDisabled)
                .buttonStyle(.bordered)
                .accessibilityLabel("Playback Or Clipboard Speech")
                .accessibilityIdentifier("saybar-playback-or-clipboard-speech")

                Button(action: openSettingsAction) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Open Settings")
                .accessibilityIdentifier("saybar-open-settings")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct MenuPickerComponent: View {
    @Binding var selectedVoiceProfileName: String
    @Binding var selectedBackend: SpeakSwiftly.SpeechBackend

    let voiceProfiles: [ProfileSnapshot]
    let availableBackends: [SpeakSwiftly.SpeechBackend]
    let isVoicePickerDisabled: Bool
    let isBackendPickerDisabled: Bool

    var body: some View {
        HStack(alignment: .center) {
            Picker("Voice Profile", selection: $selectedVoiceProfileName) {
                ForEach(voiceProfiles, id: \.profileName) { profile in
                    Text(profile.profileName).tag(profile.profileName)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .disabled(isVoicePickerDisabled)
            .accessibilityIdentifier("saybar-voice-profile-picker")

            Picker("Speech Backend", selection: $selectedBackend) {
                ForEach(availableBackends, id: \.self) { backend in
                    Text(backend.rawValue).tag(backend)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .disabled(isBackendPickerDisabled)
            .accessibilityIdentifier("saybar-speech-backend-picker")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-menu-picker-row")
    }
}

struct MenuQuickConfigSurfaceComponent: View {
    @Binding var selectedVoiceProfileName: String
    @Binding var selectedBackend: SpeakSwiftly.SpeechBackend

    let voiceProfiles: [ProfileSnapshot]
    let availableBackends: [SpeakSwiftly.SpeechBackend]
    let isVoicePickerDisabled: Bool
    let isBackendPickerDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MenuPageHeaderComponent(title: "Quick Config", systemImage: "slider.horizontal.3")

            MenuPickerComponent(
                selectedVoiceProfileName: $selectedVoiceProfileName,
                selectedBackend: $selectedBackend,
                voiceProfiles: voiceProfiles,
                availableBackends: availableBackends,
                isVoicePickerDisabled: isVoicePickerDisabled,
                isBackendPickerDisabled: isBackendPickerDisabled
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("saybar-quick-config-surface")
    }
}
