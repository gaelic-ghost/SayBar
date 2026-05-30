//
//  SettingsDisplaySupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import Foundation

enum SettingsDisplaySupport {
    nonisolated static func fallback(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "None"
        }
        return value
    }

    nonisolated static func boolean(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    nonisolated static func elapsedSeconds(_ value: Double?) -> String {
        guard let value else {
            return "None"
        }
        return String(format: "%.1f seconds", value)
    }

    nonisolated static func defaultVoiceProfileName(_ profileName: String?) -> String {
        fallback(profileName)
    }

    nonisolated static func queueCount(activeCount: Int, queuedCount: Int) -> String {
        String(max(activeCount, 0) + max(queuedCount, 0))
    }

    nonisolated static func queueSummary(activeCount: Int, queuedCount: Int) -> String {
        "\(max(activeCount, 0)) active, \(max(queuedCount, 0)) queued"
    }

    nonisolated static func transportSummary(
        state: String,
        host: String?,
        port: Int?,
        path: String?
    ) -> String {
        let address = [host, port.map(String.init)].compactMap { $0 }.joined(separator: ":")
        let resolvedPath = path ?? "/"
        if address.isEmpty {
            return "\(state) at \(resolvedPath)"
        }
        return "\(state) at \(address)\(resolvedPath)"
    }
}
