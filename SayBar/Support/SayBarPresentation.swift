import SpeakSwiftlyServer

struct MenuBarHeaderPresentation: Equatable {
	let headline: String
	let detail: String
}

func makeMenuBarHeaderPresentation(
	overview: HostOverviewSnapshot,
	playback: PlaybackStatusSnapshot,
	recentErrors: [RecentErrorSnapshot],
	actionMessage: String?,
	autostartEnabled: Bool,
) -> MenuBarHeaderPresentation {
	if !autostartEnabled {
		return .init(
			headline: "SpeakSwiftlyServer is idle for this launch.",
			detail: "Embedded autostart is disabled, so SayBar has not started the in-process runtime.",
		)
	}

	if let actionMessage, !actionMessage.isEmpty {
		return .init(
			headline: headline(for: overview),
			detail: actionMessage,
		)
	}

	if let recentError = recentErrors.first?.message, !recentError.isEmpty {
		return .init(
			headline: "SpeakSwiftlyServer is running with warnings.",
			detail: recentError,
		)
	}

	if let startupError = overview.startupError, !startupError.isEmpty {
		return .init(
			headline: "SpeakSwiftlyServer hit a startup problem.",
			detail: startupError,
		)
	}

	if playback.state == "playing", let requestID = playback.activeRequest?.id {
		return .init(
			headline: "SpeakSwiftlyServer is playing audio.",
			detail: "Playback is active for request \(requestID).",
		)
	}

	if playback.state == "paused" {
		return .init(
			headline: "SpeakSwiftlyServer playback is paused.",
			detail: "The current playback queue is paused and can resume immediately.",
		)
	}

	if overview.workerStage == "resident_models_unloaded" {
		return .init(
			headline: "SpeakSwiftlyServer is ready with models unloaded.",
			detail: "Use the power control to load the resident model again before the next speech request.",
		)
	}

	if overview.workerReady || overview.serverMode == "ready" {
		return .init(
			headline: "SpeakSwiftlyServer is ready.",
			detail: "The embedded runtime is ready for voice, playback, and queue actions.",
		)
	}

	return .init(
		headline: headline(for: overview),
		detail: detail(for: overview),
	)
}

private func headline(for overview: HostOverviewSnapshot) -> String {
	switch overview.serverMode {
		case "broken":
			"SpeakSwiftlyServer is unavailable."
		case "degraded":
			"SpeakSwiftlyServer is degraded."
		case "ready":
			"SpeakSwiftlyServer is ready."
		default:
			"SpeakSwiftlyServer is starting."
	}
}

private func detail(for overview: HostOverviewSnapshot) -> String {
	switch overview.workerStage {
		case "resident_model_ready":
			"The embedded runtime is live and the resident model is loaded."
		case "resident_models_unloaded":
			"The embedded runtime is live, but resident models are currently unloaded."
		case "starting":
			"The embedded runtime is still starting inside SayBar."
		default:
			"The embedded runtime is currently reporting worker stage \(overview.workerStage)."
	}
}
