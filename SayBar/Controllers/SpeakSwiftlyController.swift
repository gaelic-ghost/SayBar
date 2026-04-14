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

	struct StatusInputs {
		struct OverviewSnapshot {
			var serverMode: String
			var workerMode: String
			var workerStage: String
			var workerReady: Bool
			var startupError: String?
			var profileCacheWarning: String?
		}

		struct RecentErrorSnapshot {
			var message: String
		}

		struct TransportSnapshot {
			var name: String
			var enabled: Bool
			var state: String
			var host: String?
			var port: Int?
			var path: String?
		}

		var isStarting: Bool
		var hasSession: Bool
		var lastFailureMessage: String?
		var overview: OverviewSnapshot?
		var recentErrors: [RecentErrorSnapshot]
		var transports: [TransportSnapshot]
		var playbackState: String?
		var activeRequestID: String?
		var generationQueueCount: Int
		var playbackQueueCount: Int
	}

	struct ServicePresentation: Equatable {
		var state: ServiceState
		var symbolName: String
		var headline: String
		var detail: String
	}

	struct MenuMetrics: Equatable {
		struct Row: Equatable, Identifiable {
			let title: String
			let value: String

			var id: String { title }
		}

		var rows: [Row]
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

	private var statusInputs: StatusInputs {
		guard let state = serverState else {
			return StatusInputs(
				isStarting: isStarting,
				hasSession: session != nil,
				lastFailureMessage: lastFailureMessage,
				overview: nil,
				recentErrors: [],
				transports: [],
				playbackState: nil,
				activeRequestID: nil,
				generationQueueCount: 0,
				playbackQueueCount: 0
			)
		}

		return StatusInputs(
			isStarting: isStarting,
			hasSession: session != nil,
			lastFailureMessage: lastFailureMessage,
			overview: .init(
				serverMode: state.overview.serverMode,
				workerMode: state.overview.workerMode,
				workerStage: state.overview.workerStage,
				workerReady: state.overview.workerReady,
				startupError: state.overview.startupError,
				profileCacheWarning: state.overview.profileCacheWarning
			),
			recentErrors: state.recentErrors.map { .init(message: $0.message) },
			transports: state.transports.map {
				.init(
					name: $0.name,
					enabled: $0.enabled,
					state: $0.state,
					host: $0.host,
					port: $0.port,
					path: $0.path
				)
			},
			playbackState: state.playback.state,
			activeRequestID: state.playback.activeRequest?.id,
			generationQueueCount: state.generationQueue.queuedCount,
			playbackQueueCount: state.playbackQueue.queuedCount
		)
	}

	private var presentation: ServicePresentation {
		Self.makePresentation(from: statusInputs, lifecycleMessage: lifecycleMessage)
	}

	var serviceState: ServiceState {
		presentation.state
	}

	var menuBarSymbolName: String {
		presentation.symbolName
	}

	var statusHeadline: String {
		presentation.headline
	}

	var statusDetail: String {
		presentation.detail
	}

	var serverState: ServerState? {
		session?.state
	}

	var menuMetrics: MenuMetrics? {
		guard let overview = statusInputs.overview else {
			return nil
		}

		return MenuMetrics(
			rows: [
				.init(title: "Worker", value: overview.workerMode),
				.init(title: "Playback", value: statusInputs.playbackState ?? "idle"),
				.init(title: "Generation Queue", value: "\(statusInputs.generationQueueCount) queued"),
				.init(title: "Playback Queue", value: "\(statusInputs.playbackQueueCount) queued")
			]
		)
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

	static func makePresentation(from inputs: StatusInputs, lifecycleMessage: String) -> ServicePresentation {
		let state = deriveServiceState(from: inputs)

		let symbolName: String = switch state {
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

		let headline: String = switch state {
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

		let detail: String

		if let lastFailureMessage = inputs.lastFailureMessage, !inputs.hasSession {
			detail = lastFailureMessage
		} else if let overview = inputs.overview {
			if let startupError = overview.startupError, !startupError.isEmpty {
				detail = startupError
			} else if let recentError = inputs.recentErrors.first {
				detail = recentError.message
			} else if let transportIssue = inputs.transports.first(where: { $0.enabled && $0.state != "listening" }) {
				detail = "The \(transportIssue.name.uppercased()) surface is enabled, but it is currently reporting `\(transportIssue.state)` instead of `listening`."
			} else if let profileWarning = overview.profileCacheWarning, !profileWarning.isEmpty {
				detail = profileWarning
			} else if state == .ready {
				if let activeRequestID = inputs.activeRequestID, let playbackState = inputs.playbackState {
					detail = "Playback is currently `\(playbackState)` for request `\(activeRequestID)`."
				} else {
					detail = "The embedded session is running inside the SayBar app process."
				}
			} else {
				detail = "Worker mode is `\(overview.workerMode)` at stage `\(overview.workerStage)`."
			}
		} else {
			detail = lifecycleMessage
		}

		return ServicePresentation(
			state: state,
			symbolName: symbolName,
			headline: headline,
			detail: detail
		)
	}

	private static func deriveServiceState(from inputs: StatusInputs) -> ServiceState {
		if inputs.isStarting {
			return .starting
		}

		guard let overview = inputs.overview else {
			return inputs.lastFailureMessage == nil ? .stopped : .broken
		}

		if let startupError = overview.startupError, !startupError.isEmpty {
			return .broken
		}

		if overview.serverMode == "ready", overview.workerReady {
			return inputs.recentErrors.isEmpty ? .ready : .degraded
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

		if overview.serverMode == "degraded" || !inputs.recentErrors.isEmpty {
			return .degraded
		}

		return overview.workerReady ? .ready : .starting
	}
}
