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
	) throws -> HostOverviewSnapshot {
		try decode(
			HostOverviewSnapshot.self,
			from: [
				"service": "speak-swiftly-server",
				"environment": "tests",
				"default_voice_profile_name": NSNull(),
				"server_mode": serverMode,
				"worker_mode": workerMode,
				"worker_stage": workerStage,
				"worker_ready": workerReady,
				"startup_error": startupError ?? NSNull(),
				"profile_cache_state": "ready",
				"profile_cache_warning": NSNull(),
				"profile_count": 2,
				"last_profile_refresh_at": NSNull(),
			],
		)
	}

	private func makePlayback(
		state: String,
		activeRequestID: String? = nil,
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
				"stable_buffer_target_ms": NSNull(),
			],
		)
	}

	private func makeRecentError(message: String) throws -> RecentErrorSnapshot {
		try decode(
			RecentErrorSnapshot.self,
			from: [
				"occurred_at": "2026-04-19T00:00:00Z",
				"source": "playback",
				"code": "runtime_warning",
				"message": message,
			],
		)
	}

	private func decode<T: Decodable>(_ type: T.Type, from object: [String: Any]) throws -> T {
		let data = try JSONSerialization.data(withJSONObject: object)
		return try JSONDecoder().decode(type, from: data)
	}

	@Test
	@MainActor
	func idlePresentationExplainsAutostartDisabled() throws {
		let presentation = try makeMenuBarHeaderPresentation(
			overview: makeOverview(
				serverMode: "starting",
				workerMode: "starting",
				workerStage: "starting",
				workerReady: false,
			),
			playback: makePlayback(state: "idle"),
			recentErrors: [],
			actionMessage: nil,
			autostartEnabled: false,
		)

		#expect(presentation.headline == "SpeakSwiftlyServer is idle for this launch.")
	}

	@Test
	@MainActor
	func recentErrorsOutrankGenericReadyState() throws {
		let presentation = try makeMenuBarHeaderPresentation(
			overview: makeOverview(
				serverMode: "ready",
				workerMode: "ready",
				workerStage: "resident_model_ready",
				workerReady: true,
			),
			playback: makePlayback(state: "idle"),
			recentErrors: [makeRecentError(message: "Playback drained with a decoder warning.")],
			actionMessage: nil,
			autostartEnabled: true,
		)

		#expect(presentation.headline == "SpeakSwiftlyServer is running with warnings.")
		#expect(presentation.detail == "Playback drained with a decoder warning.")
	}

	@Test
	@MainActor
	func startupErrorsOutrankGenericStatus() throws {
		let presentation = try makeMenuBarHeaderPresentation(
			overview: makeOverview(
				serverMode: "broken",
				workerMode: "broken",
				workerStage: "failed",
				workerReady: false,
				startupError: "The embedded runtime could not load its startup configuration.",
			),
			playback: makePlayback(state: "idle"),
			recentErrors: [],
			actionMessage: nil,
			autostartEnabled: true,
		)

		#expect(presentation.headline == "SpeakSwiftlyServer hit a startup problem.")
		#expect(presentation.detail == "The embedded runtime could not load its startup configuration.")
	}

	@Test
	@MainActor
	func playingStateShowsActiveRequest() throws {
		let presentation = try makeMenuBarHeaderPresentation(
			overview: makeOverview(
				serverMode: "ready",
				workerMode: "ready",
				workerStage: "resident_model_ready",
				workerReady: true,
			),
			playback: makePlayback(state: "playing", activeRequestID: "req-123"),
			recentErrors: [],
			actionMessage: nil,
			autostartEnabled: true,
		)

		#expect(presentation.headline == "SpeakSwiftlyServer is playing audio.")
		#expect(presentation.detail == "Playback is active for request req-123.")
	}

	@Test
	@MainActor
	func unloadedStateExplainsPowerAction() throws {
		let presentation = try makeMenuBarHeaderPresentation(
			overview: makeOverview(
				serverMode: "ready",
				workerMode: "ready",
				workerStage: "resident_models_unloaded",
				workerReady: true,
			),
			playback: makePlayback(state: "idle"),
			recentErrors: [],
			actionMessage: nil,
			autostartEnabled: true,
		)

		#expect(presentation.headline == "SpeakSwiftlyServer is ready with models unloaded.")
	}
}
