//
//  MenuBarActionSupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import Foundation
import SpeakSwiftly

enum MenuBarActionSupport {
    enum ResidentModelCommand: Equatable {
        case reload
        case unload
    }

    enum PlaybackCommand: Equatable {
        case pause
        case resume
        case submitClipboardSpeech
    }

    enum ClipboardSpeechResult: Equatable {
        case emptyClipboard
        case queued
    }

    nonisolated static func residentModelCommand(workerStage: String) -> ResidentModelCommand {
        workerStage == "resident_models_unloaded" ? .reload : .unload
    }

    nonisolated static func playbackCommand(playbackState: String) -> PlaybackCommand {
        switch playbackState {
            case "playing":
                return .pause
            case "paused":
                return .resume
            default:
                return .submitClipboardSpeech
        }
    }

    nonisolated static func normalizedClipboardText(_ text: String?) -> String {
        text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @MainActor
    static func refreshVoiceProfilesIfNeeded(
        voiceProfilesAreEmpty: Bool,
        refreshVoiceProfiles: () async throws -> Void
    ) async throws -> Bool {
        guard voiceProfilesAreEmpty else {
            return false
        }

        try await refreshVoiceProfiles()
        return true
    }

    @MainActor
    static func setDefaultVoiceProfile(
        profileName: String,
        setDefaultVoiceProfileName: (String) async throws -> String
    ) async throws -> String? {
        guard !profileName.isEmpty else {
            return nil
        }

        return try await setDefaultVoiceProfileName(profileName)
    }

    @MainActor
    static func switchSpeechBackend(
        to backend: SpeakSwiftly.SpeechBackend,
        switchSpeechBackend: (SpeakSwiftly.SpeechBackend) async throws -> Void
    ) async throws -> String {
        try await switchSpeechBackend(backend)
        return backend.rawValue
    }

    @MainActor
    static func queueClipboardSpeech(
        clipboardText: String?,
        queueLiveSpeech: (String) async throws -> Void
    ) async throws -> ClipboardSpeechResult {
        let pastedText = normalizedClipboardText(clipboardText)

        guard !pastedText.isEmpty else {
            return .emptyClipboard
        }

        try await queueLiveSpeech(pastedText)
        return .queued
    }
}
