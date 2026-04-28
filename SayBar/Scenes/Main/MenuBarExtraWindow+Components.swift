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
    let filledSlotCount: Int
    let totalSlotCount: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label): \(filledSlotCount) of \(totalSlotCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .center, spacing: 6) {
                ForEach(0..<totalSlotCount, id: \.self) { index in
                    QueueSlotShape(isFilled: index < filledSlotCount)
                }
            }
        }
    }
}

private struct QueueSlotShape: View {
    let isFilled: Bool

    var body: some View {
        Rectangle()
            .fill(isFilled ? Color.accentColor : .clear)
            .overlay {
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 1)
            }
            .frame(width: 32, height: 40)
            .accessibilityHidden(true)
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
