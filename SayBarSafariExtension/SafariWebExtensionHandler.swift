//
//  SafariWebExtensionHandler.swift
//  SayBarSafariExtension
//
//  Created by Gale Williams on 6/24/26.
//

import SafariServices
import OSLog

@MainActor
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "browser-extension")
    private let queueClient = BrowserSpeechQueueClient()

    func beginRequest(with context: NSExtensionContext) {
        Task { @MainActor in
            do {
                let message = try Self.captureMessage(from: context)
                let markdown = try BrowserCaptureFormatter.speechMarkdown(from: message.payload)
                let request = Self.speechRequest(from: message.payload, markdown: markdown)

                Self.logger.debug(
                    "SayBar received Safari browser capture for queueing. title='\(message.payload.title, privacy: .private)' url='\(message.payload.url, privacy: .private)' characters=\(markdown.count, privacy: .public)"
                )

                let accepted = try await queueClient.queue(request)
                Self.logger.debug("SayBar queued Safari browser capture as request '\(accepted.requestID, privacy: .public)'.")
                Self.complete(context, payload: BrowserCaptureNativeResponse(
                    requestID: accepted.requestID,
                    characterCount: markdown.count
                ).messagePayload)
            } catch {
                Self.logger.error("SayBar could not queue Safari browser capture. Likely cause: \(error.localizedDescription, privacy: .public)")
                Self.complete(context, payload: [
                    "ok": false,
                    "error": error.localizedDescription,
                ])
            }
        }
    }

    private static func captureMessage(from context: NSExtensionContext) throws -> BrowserCaptureMessage {
        guard let item = context.inputItems.first as? NSExtensionItem,
              let message = item.userInfo?[SFExtensionMessageKey],
              JSONSerialization.isValidJSONObject(message)
        else {
            throw BrowserCaptureError.invalidMessage
        }

        let data = try JSONSerialization.data(withJSONObject: message)
        let captureMessage = try JSONDecoder().decode(BrowserCaptureMessage.self, from: data)
        guard captureMessage.type == "saybar.pageTextCaptured" else {
            throw BrowserCaptureError.invalidMessage
        }

        return captureMessage
    }

    private static func speechRequest(from payload: BrowserCapturePayload, markdown: String) -> BrowserSpeechRequest {
        BrowserSpeechRequest(
            text: markdown,
            requestContext: .init(
                source: "Safari",
                topic: normalizedOptional(payload.title),
                attributes: .init(
                    surface: "browser_extension",
                    browserName: "Safari",
                    browserURL: payload.url,
                    captureMode: payload.captureMode,
                    capturedAt: payload.capturedAt
                ),
                prefacePolicy: nil
            )
        )
    }

    private static func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func complete(_ context: NSExtensionContext, payload: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: payload]
        context.completeRequest(returningItems: [response])
    }
}
