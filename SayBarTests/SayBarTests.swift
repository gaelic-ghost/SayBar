//
//  SayBarTests.swift
//  SayBarTests
//
//  Created by Gale Williams on 3/30/26.
//

import Testing
@testable import SayBar

struct SayBarTests {

	@Test
	@MainActor
	func brokenPresentationUsesStartupErrorDetails() {
		let presentation = SpeakSwiftlyController.makePresentation(
			from: .init(
				isStarting: false,
				hasSession: true,
				lastFailureMessage: nil,
				overview: .init(
					serverMode: "broken",
					workerMode: "broken",
					workerStage: "failed",
					workerReady: false,
					startupError: "The embedded runtime could not load its startup configuration.",
					profileCacheWarning: nil
				),
				recentErrors: [],
				transports: [],
				playbackState: nil,
				activeRequestID: nil
			),
			lifecycleMessage: "unused"
		)

		#expect(presentation.state == .broken)
		#expect(presentation.symbolName == "xmark.octagon.fill")
		#expect(presentation.detail == "The embedded runtime could not load its startup configuration.")
	}

	@Test
	@MainActor
	func degradedPresentationPrefersRecentErrorsOverTransportWarnings() {
		let presentation = SpeakSwiftlyController.makePresentation(
			from: .init(
				isStarting: false,
				hasSession: true,
				lastFailureMessage: nil,
				overview: .init(
					serverMode: "ready",
					workerMode: "ready",
					workerStage: "idle",
					workerReady: true,
					startupError: nil,
					profileCacheWarning: "unused"
				),
				recentErrors: [.init(message: "Playback drained with a decoder warning.")],
				transports: [
					.init(name: "mcp", enabled: true, state: "connecting", host: "127.0.0.1", port: 8080, path: nil)
				],
				playbackState: nil,
				activeRequestID: nil
			),
			lifecycleMessage: "unused"
		)

		#expect(presentation.state == .degraded)
		#expect(presentation.headline == "SpeakSwiftlyServer is running with warnings.")
		#expect(presentation.detail == "Playback drained with a decoder warning.")
	}

	@Test
	@MainActor
	func readyPresentationReportsActivePlaybackRequest() {
		let presentation = SpeakSwiftlyController.makePresentation(
			from: .init(
				isStarting: false,
				hasSession: true,
				lastFailureMessage: nil,
				overview: .init(
					serverMode: "ready",
					workerMode: "ready",
					workerStage: "idle",
					workerReady: true,
					startupError: nil,
					profileCacheWarning: nil
				),
				recentErrors: [],
				transports: [
					.init(name: "mcp", enabled: true, state: "listening", host: "127.0.0.1", port: 8080, path: nil)
				],
				playbackState: "playing",
				activeRequestID: "req-123"
			),
			lifecycleMessage: "unused"
		)

		#expect(presentation.state == .ready)
		#expect(presentation.symbolName == "waveform.and.mic")
		#expect(presentation.detail == "Playback is currently `playing` for request `req-123`.")
	}

	@Test
	@MainActor
	func stoppedPresentationUsesLifecycleMessageWithoutSession() {
		let presentation = SpeakSwiftlyController.makePresentation(
			from: .init(
				isStarting: false,
				hasSession: false,
				lastFailureMessage: nil,
				overview: nil,
				recentErrors: [],
				transports: [],
				playbackState: nil,
				activeRequestID: nil
			),
			lifecycleMessage: "SayBar has not started the embedded session yet."
		)

		#expect(presentation.state == .stopped)
		#expect(presentation.headline == "SpeakSwiftlyServer is stopped.")
		#expect(presentation.detail == "SayBar has not started the embedded session yet.")
	}

	@Test
	@MainActor
	func startingPresentationWinsWhileStartupIsInFlight() {
		let presentation = SpeakSwiftlyController.makePresentation(
			from: .init(
				isStarting: true,
				hasSession: false,
				lastFailureMessage: nil,
				overview: .init(
					serverMode: "broken",
					workerMode: "broken",
					workerStage: "failed",
					workerReady: false,
					startupError: "This error should not outrank the startup state.",
					profileCacheWarning: nil
				),
				recentErrors: [],
				transports: [],
				playbackState: nil,
				activeRequestID: nil
			),
			lifecycleMessage: "unused"
		)

		#expect(presentation.state == .starting)
		#expect(presentation.headline == "SpeakSwiftlyServer is starting inside SayBar.")
	}

}
