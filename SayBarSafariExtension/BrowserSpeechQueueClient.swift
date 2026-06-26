import Foundation

struct BrowserSpeechQueueClient {
    var endpoint = URL(string: "http://127.0.0.1:7339/speech/live")!
    var session: URLSession = .shared

    func queue(_ request: BrowserSpeechRequest) async throws -> BrowserSpeechAcceptedResponse {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BrowserCaptureError.queueFailed(0, "The embedded runtime did not return an HTTP response.")
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "The embedded runtime returned a non-text error body."
            throw BrowserCaptureError.queueFailed(httpResponse.statusCode, body)
        }

        return try JSONDecoder().decode(BrowserSpeechAcceptedResponse.self, from: data)
    }
}
