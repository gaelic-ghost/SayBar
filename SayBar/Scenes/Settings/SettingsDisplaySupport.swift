//
//  SettingsDisplaySupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import Foundation
import SpeakSwiftlyServer

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

    nonisolated static func count(_ value: Int?) -> String {
        guard let value else {
            return "None"
        }
        return String(max(value, 0))
    }

    nonisolated static func list(_ values: [String]) -> String {
        if values.isEmpty {
            return "None"
        }
        return values.joined(separator: ", ")
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

    nonisolated static func networkAudioEndpoint(
        _ endpoint: NetworkAudioEndpointSnapshot
    ) -> String {
        switch endpoint.kind {
            case "host_port":
                guard let host = endpoint.host else {
                    return "host_port"
                }
                guard let port = endpoint.port else {
                    return host
                }
                return "\(host):\(port)"
            case "bonjour_service":
                return fallback(endpoint.name)
            default:
                return endpoint.kind
        }
    }

    nonisolated static func networkAudioCapabilities(
        _ capabilities: NetworkAudioCapabilitiesSnapshot
    ) -> String {
        let sampleRates = capabilities.sampleRates.map(String.init).joined(separator: ", ")
        let channelCounts = capabilities.channelCounts.map(String.init).joined(separator: ", ")
        let formats = list(capabilities.sampleFormats)
        return "v\(capabilities.protocolVersion); \(formats); \(sampleRates) Hz; \(channelCounts) channel(s)"
    }
}
