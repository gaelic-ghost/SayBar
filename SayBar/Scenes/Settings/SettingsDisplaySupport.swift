//
//  SettingsDisplaySupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

enum SettingsDisplaySupport {
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
