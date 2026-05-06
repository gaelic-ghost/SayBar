//
//  RuntimeE2ETransportSupport.swift
//  SayBarUITests
//
//  Created by Gale Williams on 5/6/26.
//

import Foundation

struct RuntimeE2EHTTPClient {
    let baseURL: URL
    var requestTimeout: TimeInterval = 120

    func request(
        path: String,
        method: String,
        jsonBody: [String: Any]? = nil
    ) async throws -> RuntimeE2EHTTPResponse {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.timeoutInterval = requestTimeout
        request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        if let jsonBody {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RuntimeE2EError("Runtime E2E HTTP request to '\(path)' did not return an HTTPURLResponse.")
        }

        return RuntimeE2EHTTPResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            data: data
        )
    }

    func decoded<Value: Decodable>(
        _ type: Value.Type,
        path: String,
        method: String = "GET",
        jsonBody: [String: Any]? = nil,
        acceptedStatusCodes: Set<Int>? = nil
    ) async throws -> Value {
        let response = try await request(path: path, method: method, jsonBody: jsonBody)
        let acceptedStatus = acceptedStatusCodes?.contains(response.statusCode) ?? (200...299).contains(response.statusCode)
        guard acceptedStatus else {
            throw RuntimeE2EError(
                "Runtime E2E HTTP request to '\(path)' returned HTTP \(response.statusCode). Body: \(response.text)"
            )
        }

        return try runtimeE2EDecode(type, from: response.data)
    }
}

struct RuntimeE2EHTTPResponse {
    let statusCode: Int
    let headers: [AnyHashable: Any]
    let data: Data

    var text: String {
        String(decoding: data, as: UTF8.self)
    }
}

struct RuntimeE2EMCPClient {
    let baseURL: URL
    let path: String
    let sessionID: String

    static func connect(mcpURL: URL) async throws -> RuntimeE2EMCPClient {
        let endpoint = try RuntimeE2EMCPEndpoint(mcpURL: mcpURL)

        let initializeResponse = try await post(
            baseURL: endpoint.baseURL,
            path: endpoint.path,
            jsonBody: [
                "jsonrpc": "2.0",
                "id": "initialize-1",
                "method": "initialize",
                "params": [
                    "protocolVersion": "2025-11-25",
                    "capabilities": [:],
                    "clientInfo": [
                        "name": "SayBarRuntimeE2E",
                        "version": "1.0",
                    ],
                ],
            ],
            sessionID: nil
        )
        guard (200...299).contains(initializeResponse.statusCode) else {
            throw RuntimeE2EError(
                "Runtime E2E MCP initialize at '\(mcpURL.absoluteString)' returned HTTP \(initializeResponse.statusCode). Body: \(initializeResponse.text)"
            )
        }

        let sessionID = try runtimeE2EHeader("Mcp-Session-Id", in: initializeResponse.headers)
        _ = try runtimeE2EMCPEnvelope(from: initializeResponse.data)

        let initializedResponse = try await post(
            baseURL: endpoint.baseURL,
            path: endpoint.path,
            jsonBody: [
                "jsonrpc": "2.0",
                "method": "notifications/initialized",
            ],
            sessionID: sessionID
        )
        guard (200...299).contains(initializedResponse.statusCode) else {
            throw RuntimeE2EError(
                "Runtime E2E MCP initialized notification at '\(mcpURL.absoluteString)' returned HTTP \(initializedResponse.statusCode). Body: \(initializedResponse.text)"
            )
        }

        return RuntimeE2EMCPClient(
            baseURL: endpoint.baseURL,
            path: endpoint.path,
            sessionID: sessionID
        )
    }

    func callTool(name: String, arguments: [String: Any] = [:]) async throws -> [String: Any] {
        let envelope = try await callMethod(
            "tools/call",
            params: [
                "name": name,
                "arguments": arguments,
            ]
        )
        if let error = envelope["error"] as? [String: Any] {
            throw RuntimeE2EError("Runtime E2E MCP tool '\(name)' failed with payload: \(error)")
        }

        let result = try runtimeE2EDictionary("result", in: envelope)
        let content = try runtimeE2EArray("content", in: result)
        let first = try runtimeE2EFirstDictionary(in: content)
        let text = try runtimeE2EString("text", in: first)
        let payload = try JSONSerialization.jsonObject(with: Data(text.utf8))
        guard let object = payload as? [String: Any] else {
            throw RuntimeE2EError("Runtime E2E MCP tool '\(name)' returned '\(type(of: payload))' instead of a JSON object.")
        }

        return object
    }

    func readResourceJSON(uri: String) async throws -> [String: Any] {
        let envelope = try await callMethod("resources/read", params: ["uri": uri])
        if let error = envelope["error"] as? [String: Any] {
            throw RuntimeE2EError("Runtime E2E MCP resource read for '\(uri)' failed with payload: \(error)")
        }

        let result = try runtimeE2EDictionary("result", in: envelope)
        let contents = try runtimeE2EArray("contents", in: result)
        let first = try runtimeE2EFirstDictionary(in: contents)
        let text = try runtimeE2EString("text", in: first)
        let payload = try JSONSerialization.jsonObject(with: Data(text.utf8))
        guard let object = payload as? [String: Any] else {
            throw RuntimeE2EError("Runtime E2E MCP resource '\(uri)' returned '\(type(of: payload))' instead of a JSON object.")
        }

        return object
    }

    func callMethod(_ method: String, params: [String: Any]) async throws -> [String: Any] {
        let response = try await Self.post(
            baseURL: baseURL,
            path: path,
            jsonBody: [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "method": method,
                "params": params,
            ],
            sessionID: sessionID
        )
        guard (200...299).contains(response.statusCode) else {
            throw RuntimeE2EError(
                "Runtime E2E MCP method '\(method)' returned HTTP \(response.statusCode). Body: \(response.text)"
            )
        }

        return try runtimeE2EMCPEnvelope(from: response.data)
    }

    private static func post(
        baseURL: URL,
        path: String,
        jsonBody: [String: Any],
        sessionID: String?
    ) async throws -> RuntimeE2EHTTPResponse {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        if let sessionID {
            request.setValue(sessionID, forHTTPHeaderField: "Mcp-Session-Id")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RuntimeE2EError("Runtime E2E MCP transport did not return an HTTPURLResponse.")
        }

        return RuntimeE2EHTTPResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            data: data
        )
    }
}

struct RuntimeE2EMCPEndpoint {
    let baseURL: URL
    let path: String

    init(mcpURL: URL) throws {
        guard var components = URLComponents(url: mcpURL, resolvingAgainstBaseURL: false),
              components.scheme != nil,
              components.host != nil
        else {
            throw RuntimeE2EError("Runtime E2E MCP URL '\(mcpURL.absoluteString)' is not an absolute URL.")
        }

        let path = components.path.isEmpty ? "/mcp" : components.path
        components.path = ""
        components.query = nil
        components.fragment = nil

        guard let baseURL = components.url else {
            throw RuntimeE2EError("Runtime E2E could not derive a base URL from MCP URL '\(mcpURL.absoluteString)'.")
        }

        self.baseURL = baseURL
        self.path = path
    }
}

struct RuntimeE2EReadinessSnapshot: Decodable {
    let status: String
    let workerMode: String
    let workerStage: String
    let workerReady: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case workerMode = "worker_mode"
        case workerStage = "worker_stage"
        case workerReady = "worker_ready"
    }
}

struct RuntimeE2EOverviewSnapshot: Decodable {
    let serverMode: String
    let workerMode: String
    let workerStage: String
    let generationQueue: RuntimeE2EQueueSnapshot
    let playbackQueue: RuntimeE2EQueueSnapshot
    let playback: RuntimeE2EPlaybackSnapshot
    let transports: [RuntimeE2ETransportSnapshot]

    enum CodingKeys: String, CodingKey {
        case serverMode = "server_mode"
        case workerMode = "worker_mode"
        case workerStage = "worker_stage"
        case generationQueue = "generation_queue"
        case playbackQueue = "playback_queue"
        case playback
        case transports
    }

    var hasNoActiveSpeechWork: Bool {
        generationQueue.activeCount == 0
            && generationQueue.queuedCount == 0
            && playbackQueue.activeCount == 0
            && playbackQueue.queuedCount == 0
            && playback.activeRequest == nil
            && playback.state != "playing"
    }

    func transportState(named name: String) -> String? {
        transports.first { $0.name == name }?.state
    }
}

struct RuntimeE2EQueueSnapshot: Decodable {
    let activeCount: Int
    let queuedCount: Int

    enum CodingKeys: String, CodingKey {
        case activeCount = "active_count"
        case queuedCount = "queued_count"
    }
}

struct RuntimeE2EPlaybackSnapshot: Decodable {
    let state: String
    let activeRequest: RuntimeE2ERequestReference?

    enum CodingKeys: String, CodingKey {
        case state
        case activeRequest = "active_request"
    }
}

struct RuntimeE2ETransportSnapshot: Decodable {
    let name: String
    let state: String
}

struct RuntimeE2ERequestReference: Decodable {
    let id: String
}

struct RuntimeE2EAcceptedRequest: Decodable {
    let requestID: String

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
    }
}

struct RuntimeE2ERequestList: Decodable {
    let requests: [RuntimeE2EJobSnapshot]
}

struct RuntimeE2EJobSnapshot: Decodable {
    let requestID: String
    let status: String
    let history: [RuntimeE2EJobEvent]
    let terminalEvent: RuntimeE2EJobEvent?

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case status
        case history
        case terminalEvent = "terminal_event"
    }

    var completedSuccessfully: Bool {
        status == "completed" && terminalEvent?.ok == true
    }
}

struct RuntimeE2EJobEvent: Decodable {
    let id: String?
    let event: String?
    let op: String?
    let stage: String?
    let ok: Bool?
    let message: String?
    let code: String?
}

struct RuntimeE2EError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

func runtimeE2EDecode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
    do {
        return try JSONDecoder().decode(type, from: data)
    } catch {
        let body = String(decoding: data, as: UTF8.self)
        throw RuntimeE2EError(
            "Runtime E2E could not decode \(type) from JSON. Underlying error: \(error). Body: \(body)"
        )
    }
}

func runtimeE2EMCPEnvelope(from data: Data) throws -> [String: Any] {
    let body = String(decoding: data, as: UTF8.self)
    if let dataLine = body
        .split(separator: "\n")
        .reversed()
        .first(where: { $0.hasPrefix("data: ") && !$0.dropFirst("data: ".count).isEmpty }) {
        return try runtimeE2EMCPEnvelopeJSON(
            from: Data(dataLine.dropFirst("data: ".count).utf8),
            rawBody: body
        )
    }

    return try runtimeE2EMCPEnvelopeJSON(from: data, rawBody: body)
}

func runtimeE2EMCPEnvelopeJSON(from data: Data, rawBody: String) throws -> [String: Any] {
    let json = try JSONSerialization.jsonObject(with: data)
    if let object = json as? [String: Any] {
        return object
    }

    if let objects = json as? [[String: Any]] {
        if let envelope = objects.first(where: { $0["result"] != nil || $0["error"] != nil }) {
            return envelope
        }
        if let first = objects.first {
            return first
        }
        throw RuntimeE2EError("Runtime E2E MCP response decoded to an empty array. Raw body: \(rawBody)")
    }

    throw RuntimeE2EError("Runtime E2E MCP response decoded to '\(type(of: json))'. Raw body: \(rawBody)")
}

func runtimeE2EHeader(_ name: String, in headers: [AnyHashable: Any]) throws -> String {
    for (key, value) in headers {
        if String(describing: key).caseInsensitiveCompare(name) == .orderedSame,
           let value = value as? String,
           !value.isEmpty {
            return value
        }
    }

    throw RuntimeE2EError("Runtime E2E response was missing the required '\(name)' header.")
}

func runtimeE2EDictionary(_ key: String, in object: [String: Any]) throws -> [String: Any] {
    guard let value = object[key] as? [String: Any] else {
        throw RuntimeE2EError("Runtime E2E expected '\(key)' to be a JSON object.")
    }

    return value
}

func runtimeE2EArray(_ key: String, in object: [String: Any]) throws -> [[String: Any]] {
    guard let value = object[key] as? [[String: Any]] else {
        throw RuntimeE2EError("Runtime E2E expected '\(key)' to be an array of JSON objects.")
    }

    return value
}

func runtimeE2EFirstDictionary(in array: [[String: Any]]) throws -> [String: Any] {
    guard let first = array.first else {
        throw RuntimeE2EError("Runtime E2E expected at least one JSON object in the array.")
    }

    return first
}

func runtimeE2EString(_ key: String, in object: [String: Any]) throws -> String {
    guard let value = object[key] as? String, !value.isEmpty else {
        throw RuntimeE2EError("Runtime E2E expected '\(key)' to be a non-empty string.")
    }

    return value
}
