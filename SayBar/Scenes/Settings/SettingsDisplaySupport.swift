//
//  SettingsDisplaySupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

enum SettingsDisplaySupport {
    nonisolated static func enabledStatus(_ isEnabled: Bool) -> String {
        isEnabled ? "Enabled" : "Disabled"
    }

    nonisolated static func defaultVoiceProfileName(_ profileName: String?) -> String {
        profileName ?? "None"
    }

    nonisolated static func queueCount(activeCount: Int, queuedCount: Int) -> String {
        String(max(activeCount, 0) + max(queuedCount, 0))
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
