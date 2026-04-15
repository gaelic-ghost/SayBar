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

	private var presentation: ServicePresentation {
		Self.makePresentation(
			isStarting: isStarting,
			hasSession: session != nil,
			lifecycleMessage: lifecycleMessage,
			lastFailureMessage: lastFailureMessage,
			overview: serverState?.overview,
			recentErrors: serverState?.recentErrors ?? [],
			transports: serverState?.transports ?? [],
			playback: serverState?.playback
		)
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
		guard let state = serverState else {
			return nil
		}

		return MenuMetrics(
			rows: [
				.init(title: "Worker", value: state.overview.workerMode),
				.init(title: "Playback", value: state.playback.state),
				.init(title: "Generation Queue", value: "\(state.generationQueue.queuedCount) queued"),
				.init(title: "Playback Queue", value: "\(state.playbackQueue.queuedCount) queued")
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

	static func makePresentation(
		isStarting: Bool,
		hasSession: Bool,
		lifecycleMessage: String,
		lastFailureMessage: String?,
		overview: HostOverviewSnapshot?,
		recentErrors: [RecentErrorSnapshot],
		transports: [TransportStatusSnapshot],
		playback: PlaybackStatusSnapshot?
	) -> ServicePresentation {
		let state = deriveServiceState(
			isStarting: isStarting,
			lastFailureMessage: lastFailureMessage,
			overview: overview,
			recentErrors: recentErrors
		)

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

		if let lastFailureMessage, !hasSession {
			detail = lastFailureMessage
		} else if let overview {
			if let startupError = overview.startupError, !startupError.isEmpty {
				detail = startupError
			} else if let recentError = recentErrors.first {
				detail = recentError.message
			} else if let transportIssue = transports.first(where: { $0.enabled && $0.state != "listening" }) {
				detail = "The \(transportIssue.name.uppercased()) surface is enabled, but it is currently reporting `\(transportIssue.state)` instead of `listening`."
			} else if let profileWarning = overview.profileCacheWarning, !profileWarning.isEmpty {
				detail = profileWarning
			} else if state == .ready {
				if let activeRequestID = playback?.activeRequest?.id, let playbackState = playback?.state {
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

	private static func deriveServiceState(
		isStarting: Bool,
		lastFailureMessage: String?,
		overview: HostOverviewSnapshot?,
		recentErrors: [RecentErrorSnapshot]
	) -> ServiceState {
		if isStarting {
			return .starting
		}

		guard let overview else {
			return lastFailureMessage == nil ? .stopped : .broken
		}

		if let startupError = overview.startupError, !startupError.isEmpty {
			return .broken
		}

		if overview.serverMode == "ready", overview.workerReady {
			return recentErrors.isEmpty ? .ready : .degraded
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

		if overview.serverMode == "degraded" || !recentErrors.isEmpty {
			return .degraded
		}

		return overview.workerReady ? .ready : .starting
	}
}
