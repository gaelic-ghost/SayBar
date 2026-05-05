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
    }
}

struct QueueCountComponent: View {
    let summary: MenuBarDisplaySupport.QueueSummary
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label): \(summary.activeCount) active, \(summary.queuedCount) queued / \(summary.capacity)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<summary.capacity, id: \.self) { index in
                    QueueSlotShape(state: slotState(at: index))
                }
            }
        }
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

private struct QueueSlotShape: View {
    enum State {
        case active
        case queued
        case empty
    }

    let state: State

    var body: some View {
        Rectangle()
            .fill(fillColor)
            .overlay {
                Rectangle()
                    .stroke(strokeColor, lineWidth: 1)
            }
            .frame(width: 8, height: 18)
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

                Button(action: playbackAction) {
                    Image(systemName: playbackSymbolName)
                }
                .disabled(isPlaybackButtonDisabled)
                .buttonStyle(.bordered)

                Button(action: openSettingsAction) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("saybar-open-settings")
            }
        }
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

            Picker("Speech Backend", selection: $selectedBackend) {
                ForEach(availableBackends, id: \.self) { backend in
                    Text(backend.rawValue).tag(backend)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .disabled(isBackendPickerDisabled)
        }
    }
}
