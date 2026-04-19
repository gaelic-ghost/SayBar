import Foundation
import SpeakSwiftlyServer

struct EmbeddedServerLiveSpeechClient {
	private struct LiveSpeechRequestPayload: Encodable {
		let text: String
		let profileName: String?

		enum CodingKeys: String, CodingKey {
			case text
			case profileName = "profile_name"
		}
	}

	func queueClipboardSpeech(text: String, server: EmbeddedServer) async throws {
		let payload = LiveSpeechRequestPayload(
			text: text,
			profileName: server.overview.defaultVoiceProfileName,
		)
		let requestURL = liveSpeechURL(for: server)
		var request = URLRequest(url: requestURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try JSONEncoder().encode(payload)

		let (_, response) = try await URLSession.shared.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw EmbeddedServerLiveSpeechClientError(
				"SayBar reached the embedded SpeakSwiftlyServer speech route, but the response was not an HTTP response.",
			)
		}

		guard (200..<300).contains(httpResponse.statusCode) else {
			throw EmbeddedServerLiveSpeechClientError(
				"SayBar could not queue clipboard text for live speech because the embedded HTTP route returned status \(httpResponse.statusCode).",
			)
		}
	}

	private func liveSpeechURL(for server: EmbeddedServer) -> URL {
		if let transport = server.transports.first(where: { $0.name == "http" && $0.enabled && $0.host != nil && $0.port != nil }),
		   let host = transport.host,
		   let port = transport.port {
			return URL(string: "http://\(host):\(port)/speech/live")!
		}

		return URL(string: "http://127.0.0.1:7339/speech/live")!
	}
}

struct EmbeddedServerLiveSpeechClientError: LocalizedError {
	let message: String

	init(_ message: String) {
		self.message = message
	}

	var errorDescription: String? {
		message
	}
}
