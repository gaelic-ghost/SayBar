import Foundation

struct BrowserCaptureMessage: Decodable {
    let type: String
    let payload: BrowserCapturePayload
}

struct BrowserCapturePayload: Decodable, Equatable {
    let title: String
    let url: String
    let text: String
    let html: String
    let captureMode: String
    let capturedAt: String
}

struct BrowserSpeechRequest: Encodable {
    struct RequestContext: Encodable {
        struct Attributes: Encodable {
            let surface: String
            let browserName: String
            let browserURL: String
            let captureMode: String
            let capturedAt: String

            enum CodingKeys: String, CodingKey {
                case surface
                case browserName = "browser.name"
                case browserURL = "browser.url"
                case captureMode = "browser.capture_mode"
                case capturedAt = "browser.captured_at"
            }
        }

        let source: String
        let topic: String?
        let attributes: Attributes
        let prefacePolicy: String?
    }

    let text: String
    let requestContext: RequestContext

    enum CodingKeys: String, CodingKey {
        case text
        case requestContext = "request_context"
    }
}

struct BrowserSpeechAcceptedResponse: Decodable {
    let requestID: String

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
    }
}

struct BrowserCaptureNativeResponse {
    let requestID: String
    let characterCount: Int

    var messagePayload: [String: Any] {
        [
            "ok": true,
            "nativeHandoff": "queued",
            "requestID": requestID,
            "characterCount": characterCount,
        ]
    }
}
