//
//  SayBarTests.swift
//  SayBarTests
//
//  Created by Gale Williams on 3/30/26.
//

import Foundation
import SpeakSwiftlyServer
import Testing
@testable import SayBar

struct SayBarTests {

	private func makeOverview(
		serverMode: String,
		workerMode: String,
		workerStage: String,
		workerReady: Bool,
		startupError: String? = nil,
		profileCacheWarning: String? = nil
	) throws -> HostOverviewSnapshot {
		try decode(
			HostOverviewSnapshot.self,
			from: [
				"service": "embedded",
				"environment": "tests",
				"default_voice_profile_name": NSNull(),
				"server_mode": serverMode,
				"worker_mode": workerMode,
				"worker_stage": workerStage,
				"worker_ready": workerReady,
				"startup_error": startupError ?? NSNull(),
				"profile_cache_state": "ready",
				"profile_cache_warning": profileCacheWarning ?? NSNull(),
				"profile_count": 0,
				"last_profile_refresh_at": NSNull()
			]
		)
	}

	private func makeRecentError(message: String) throws -> RecentErrorSnapshot {
		try decode(
			RecentErrorSnapshot.self,
			from: [
				"occurred_at": "2026-04-17T00:00:00Z",
				"source": "playback",
				"code": "decoder_warning",
				"message": message
			]
		)
	}

	private func makeTransport(
		name: String,
		enabled: Bool,
		state: String,
		host: String? = nil,
		port: Int? = nil,
		path: String? = nil
	) throws -> TransportStatusSnapshot {
		try decode(
			TransportStatusSnapshot.self,
			from: [
				"name": name,
				"enabled": enabled,
				"state": state,
				"host": host ?? NSNull(),
				"port": port ?? NSNull(),
				"path": path ?? NSNull(),
				"advertised_address": NSNull()
			]
		)
	}

	private func makePlayback(
		state: String,
		activeRequestID: String? = nil
	) throws -> PlaybackStatusSnapshot {
		let activeRequest: Any = activeRequestID.map { id in
			[
				"id": id,
				"op": "speak",
				"profile_name": "default-femme",
			]
		} ?? NSNull()

		return try decode(
			PlaybackStatusSnapshot.self,
			from: [
				"state": state,
				"active_request": activeRequest,
				"is_stable_for_concurrent_generation": true,
				"is_rebuffering": false,
				"stable_buffered_audio_ms": NSNull(),
				"stable_buffer_target_ms": NSNull()
			]
		)
	}

	private func decode<T: Decodable>(_ type: T.Type, from object: [String: Any]) throws -> T {
		let data = try JSONSerialization.data(withJSONObject: object)
		return try JSONDecoder().decode(type, from: data)
	}

	@Test
	@MainActor
	func brokenPresentationUsesStartupErrorDetails() throws {
		let presentation = SpeakSwiftlyController.makePresentation(
			isStarting: false,
			hasSession: true,
			lifecycleMessage: "unused",
			lastFailureMessage: nil,
			overview: try makeOverview(
				serverMode: "broken",
				workerMode: "broken",
				workerStage: "failed",
				workerReady: false,
				startupError: "The embedded runtime could not load its startup configuration."
			),
			recentErrors: [],
			transports: [],
			playback: nil
		)

		#expect(presentation.state == .broken)
		#expect(presentation.symbolName == "xmark.octagon.fill")
		#expect(presentation.detail == "The embedded runtime could not load its startup configuration.")
	}

	@Test
	@MainActor
	func degradedPresentationPrefersRecentErrorsOverTransportWarnings() throws {
		let presentation = SpeakSwiftlyController.makePresentation(
			isStarting: false,
			hasSession: true,
			lifecycleMessage: "unused",
			lastFailureMessage: nil,
			overview: try makeOverview(
				serverMode: "ready",
				workerMode: "ready",
				workerStage: "idle",
				workerReady: true,
				profileCacheWarning: "unused"
			),
			recentErrors: [try makeRecentError(message: "Playback drained with a decoder warning.")],
			transports: [
				try makeTransport(name: "mcp", enabled: true, state: "connecting", host: "127.0.0.1", port: 8080)
			],
			playback: nil
		)

		#expect(presentation.state == .degraded)
		#expect(presentation.headline == "SpeakSwiftlyServer is running with warnings.")
		#expect(presentation.detail == "Playback drained with a decoder warning.")
	}

	@Test
	@MainActor
	func readyPresentationReportsActivePlaybackRequest() throws {
		let presentation = SpeakSwiftlyController.makePresentation(
			isStarting: false,
			hasSession: true,
			lifecycleMessage: "unused",
			lastFailureMessage: nil,
			overview: try makeOverview(
				serverMode: "ready",
				workerMode: "ready",
				workerStage: "idle",
				workerReady: true
			),
			recentErrors: [],
			transports: [
				try makeTransport(name: "mcp", enabled: true, state: "listening", host: "127.0.0.1", port: 8080)
			],
			playback: try makePlayback(state: "playing", activeRequestID: "req-123")
		)

		#expect(presentation.state == .ready)
		#expect(presentation.symbolName == "waveform.and.mic")
		#expect(presentation.detail == "Playback is currently `playing` for request `req-123`.")
	}

	@Test
	@MainActor
	func stoppedPresentationUsesLifecycleMessageWithoutSession() {
		let presentation = SpeakSwiftlyController.makePresentation(
			isStarting: false,
			hasSession: false,
			lifecycleMessage: "SayBar has not started the embedded session yet.",
			lastFailureMessage: nil,
			overview: nil,
			recentErrors: [],
			transports: [],
			playback: nil
		)

		#expect(presentation.state == .stopped)
		#expect(presentation.headline == "SpeakSwiftlyServer is stopped.")
		#expect(presentation.detail == "SayBar has not started the embedded session yet.")
	}

	@Test
	@MainActor
	func startingPresentationWinsWhileStartupIsInFlight() throws {
		let presentation = SpeakSwiftlyController.makePresentation(
			isStarting: true,
			hasSession: false,
			lifecycleMessage: "unused",
			lastFailureMessage: nil,
			overview: try makeOverview(
				serverMode: "broken",
				workerMode: "broken",
				workerStage: "failed",
				workerReady: false,
				startupError: "This error should not outrank the startup state."
			),
			recentErrors: [],
			transports: [],
			playback: nil
		)

		#expect(presentation.state == .starting)
		#expect(presentation.headline == "SpeakSwiftlyServer is starting inside SayBar.")
	}

}
