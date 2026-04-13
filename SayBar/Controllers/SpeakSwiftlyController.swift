//
//  SpeakSwiftlyController.swift
//  SayBar
//
//  Created by Gale Williams on 4/12/26.
//

import Foundation
import Observation
import SpeakSwiftlyServer

@MainActor
@Observable
final class SpeakSwiftlyController {

	enum ServiceState: String {
		case stopped
		case starting
		case ready
		case degraded
		case broken

		var displayName: String {
			switch self {
			case .stopped:
				"Stopped"
			case .starting:
				"Starting"
			case .ready:
				"Ready"
			case .degraded:
				"Degraded"
			case .broken:
				"Broken"
			}
		}
	}

	private(set) var session: EmbeddedServerSession?
	private(set) var lifecycleMessage = "SayBar has not started the embedded SpeakSwiftlyServer session yet."
	private(set) var lastFailureMessage: String?
	private(set) var isStarting = false
	private(set) var isStopping = false

	@ObservationIgnored
	private let autoStart: Bool

	init(autoStart: Bool = true) {
		self.autoStart = autoStart

		if autoStart {
			Task { [weak self] in
				await self?.startIfNeeded()
			}
		}
	}

	var serviceState: ServiceState {
		if isStarting {
			return .starting
		}

		guard let state = serverState else {
			return lastFailureMessage == nil ? .stopped : .broken
		}

		let overview = state.overview

		if let startupError = overview.startupError, !startupError.isEmpty {
			return .broken
		}

		if overview.serverMode == "ready", overview.workerReady {
			return state.recentErrors.isEmpty ? .ready : .degraded
		}

		if overview.serverMode == "starting" || overview.workerMode == "starting" || overview.workerStage == "starting" {
			return .starting
		}

		if overview.serverMode == "broken"
			|| overview.workerMode == "broken"
			|| overview.workerStage == "broken"
			|| overview.workerStage == "failed" {
			return .broken
		}

		if overview.serverMode == "degraded" || !state.recentErrors.isEmpty {
			return .degraded
		}

		return overview.workerReady ? .ready : .starting
	}

	var menuBarSymbolName: String {
		switch serviceState {
		case .stopped:
			"speaker.slash.fill"
		case .starting:
			"hourglass.circle.fill"
		case .ready:
			"waveform.and.mic"
		case .degraded:
			"exclamationmark.triangle.fill"
		case .broken:
			"xmark.octagon.fill"
		}
	}

	var statusHeadline: String {
		switch serviceState {
		case .stopped:
			"SpeakSwiftlyServer is stopped."
		case .starting:
			"SpeakSwiftlyServer is starting inside SayBar."
		case .ready:
			"SpeakSwiftlyServer is ready."
		case .degraded:
			"SpeakSwiftlyServer is running with warnings."
		case .broken:
			"SpeakSwiftlyServer needs attention."
		}
	}

	var statusDetail: String {
		if let lastFailureMessage, session == nil {
			return lastFailureMessage
		}

		guard let state = serverState else {
			return lifecycleMessage
		}

		let overview = state.overview

		if let startupError = overview.startupError, !startupError.isEmpty {
			return startupError
		}

		if let recentError = state.recentErrors.first {
			return recentError.message
		}

		if let transportIssue = state.transports.first(where: { $0.enabled && $0.state != "listening" }) {
			return "The \(transportIssue.name.uppercased()) surface is enabled, but it is currently reporting `\(transportIssue.state)` instead of `listening`."
		}

		if let profileWarning = overview.profileCacheWarning, !profileWarning.isEmpty {
			return profileWarning
		}

		if serviceState == .ready {
			if let activeRequest = state.playback.activeRequest {
				return "Playback is currently `\(state.playback.state)` for request `\(activeRequest.id)`."
			}

			return "The embedded session is running inside the SayBar app process."
		}

		return "Worker mode is `\(overview.workerMode)` at stage `\(overview.workerStage)`."
	}

	var serverState: ServerState? {
		session?.state
	}

	var canStart: Bool {
		session == nil && !isStarting
	}

	var canRestart: Bool {
		!isStarting && !isStopping
	}

	var canStop: Bool {
		session != nil && !isStopping
	}

	var canPausePlayback: Bool {
		guard let state = serverState else {
			return false
		}

		return state.playback.activeRequest != nil && state.playback.state != "paused"
	}

	var canResumePlayback: Bool {
		guard let state = serverState else {
			return false
		}

		return state.playback.state == "paused"
	}

	var canClearPlaybackQueue: Bool {
		guard let state = serverState else {
			return false
		}

		return state.playbackQueue.activeCount > 0 || state.playbackQueue.queuedCount > 0
	}

	var primaryActionTitle: String {
		canStart ? "Start" : "Restart"
	}

	func startIfNeeded() async {
		guard session == nil, !isStarting else {
			return
		}

		isStarting = true
		lifecycleMessage = "SayBar is starting the embedded SpeakSwiftlyServer session."
		lastFailureMessage = nil
		defer { isStarting = false }

		do {
			let session = try await EmbeddedServerSession.start()
			self.session = session
			lifecycleMessage = "SayBar started the embedded SpeakSwiftlyServer session successfully."
		} catch {
			session = nil
			let description = error.localizedDescription
			lastFailureMessage = "SayBar could not start the embedded SpeakSwiftlyServer session. Likely cause: \(description)"
			lifecycleMessage = "The embedded session failed to start."
		}
	}

	func stopIfRunning() async {
		guard let session, !isStopping else {
			return
		}

		isStopping = true
		lifecycleMessage = "SayBar is stopping the embedded SpeakSwiftlyServer session."
		defer { isStopping = false }

		do {
			try await session.stop()
			self.session = nil
			lastFailureMessage = nil
			lifecycleMessage = "SayBar stopped the embedded SpeakSwiftlyServer session."
		} catch {
			let description = error.localizedDescription
			lastFailureMessage = "SayBar asked the embedded SpeakSwiftlyServer session to stop, but shutdown did not finish cleanly. Likely cause: \(description)"
			lifecycleMessage = "The embedded session reported a shutdown problem."
		}
	}

	func restart() async {
		lifecycleMessage = "SayBar is restarting the embedded SpeakSwiftlyServer session."
		await stopIfRunning()
		await startIfNeeded()
	}

	func pausePlayback() async {
		guard let state = serverState else {
			return
		}

		do {
			_ = try await state.pausePlayback()
			lastFailureMessage = nil
			lifecycleMessage = "SayBar paused SpeakSwiftly playback."
		} catch {
			lastFailureMessage = "SayBar could not pause SpeakSwiftly playback. Likely cause: \(error.localizedDescription)"
		}
	}

	func resumePlayback() async {
		guard let state = serverState else {
			return
		}

		do {
			_ = try await state.resumePlayback()
			lastFailureMessage = nil
			lifecycleMessage = "SayBar resumed SpeakSwiftly playback."
		} catch {
			lastFailureMessage = "SayBar could not resume SpeakSwiftly playback. Likely cause: \(error.localizedDescription)"
		}
	}

	func clearPlaybackQueue() async {
		guard let state = serverState else {
			return
		}

		do {
			let clearedCount = try await state.clearPlaybackQueue()
			lastFailureMessage = nil
			lifecycleMessage = "SayBar cleared \(clearedCount) queued playback request(s) from SpeakSwiftlyServer."
		} catch {
			lastFailureMessage = "SayBar could not clear the SpeakSwiftly playback queue. Likely cause: \(error.localizedDescription)"
		}
	}

	func transportSummary(for snapshot: TransportStatusSnapshot) -> String {
		var components = [snapshot.name.uppercased(), snapshot.state]

		if let host = snapshot.host, let port = snapshot.port {
			components.append("\(host):\(port)")
		} else if let path = snapshot.path {
			components.append(path)
		}

		return components.joined(separator: " • ")
	}

	var autoStartEnabled: Bool {
		autoStart
	}
}
