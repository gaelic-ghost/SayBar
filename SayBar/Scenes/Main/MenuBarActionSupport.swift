//
//  MenuBarActionSupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import Foundation

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
}
