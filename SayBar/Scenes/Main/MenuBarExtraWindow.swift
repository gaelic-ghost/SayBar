//
//  MenuBarExtraWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import AppKit
import OSLog
import SpeakSwiftly
import SpeakSwiftlyServer
import SwiftUI

struct MenuBarExtraWindow: View {
	let server: EmbeddedServer
	let autostartEnabled: Bool

	@Environment(\.openSettings)
	private var openSettings

	@State
	private var actionMessage: String?

	@State
	private var isSubmittingClipboardSpeech = false

	@State
	private var isRunningVoiceAction = false

	@State
	private var isRunningBackendAction = false

	@State
	private var isRunningModelAction = false

	private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "menu-bar")

	private var statusHeadline: String {
		if !autostartEnabled {
			return "SpeakSwiftlyServer is idle for this launch."
		}

		if let recentError = server.recentErrors.first?.message, !recentError.isEmpty {
			return "SpeakSwiftlyServer is running with warnings."
		}

		if let startupError = server.overview.startupError, !startupError.isEmpty {
			return "SpeakSwiftlyServer hit a startup problem."
		}

		if server.playback.state == "playing" {
			return "SpeakSwiftlyServer is playing audio."
		}

		if server.playback.state == "paused" {
			return "SpeakSwiftlyServer playback is paused."
		}

		if server.overview.workerStage == "resident_models_unloaded" {
			return "SpeakSwiftlyServer is ready with models unloaded."
		}

		switch server.overview.serverMode {
			case "broken":
				return "SpeakSwiftlyServer is unavailable."
			case "degraded":
				return "SpeakSwiftlyServer is degraded."
			case "ready":
				return "SpeakSwiftlyServer is ready."
			default:
				return "SpeakSwiftlyServer is starting."
		}
	}

	private var statusDetail: String {
		if !autostartEnabled {
			return "Embedded autostart is disabled, so SayBar has not started the in-process runtime."
		}

		if let actionMessage, !actionMessage.isEmpty {
			return actionMessage
		}

		if let recentError = server.recentErrors.first?.message, !recentError.isEmpty {
			return recentError
		}

		if let startupError = server.overview.startupError, !startupError.isEmpty {
			return startupError
		}

		if server.playback.state == "playing", let requestID = server.playback.activeRequest?.id {
			return "Playback is active for request \(requestID)."
		}

		if server.playback.state == "paused" {
			return "The current playback queue is paused and can resume immediately."
		}

		if server.overview.workerStage == "resident_models_unloaded" {
			return "Use the power control to load the resident model again before the next speech request."
		}

		if server.overview.workerReady || server.overview.serverMode == "ready" {
			return "The embedded runtime is ready for voice, playback, and queue actions."
		}

		switch server.overview.workerStage {
			case "resident_model_ready":
				return "The embedded runtime is live and the resident model is loaded."
			case "resident_models_unloaded":
				return "The embedded runtime is live, but resident models are currently unloaded."
			case "starting":
				return "The embedded runtime is still starting inside SayBar."
			default:
				return "The embedded runtime is currently reporting worker stage \(server.overview.workerStage)."
		}
	}

	private var queueSlotCount: Int {
		min(server.generationQueue.activeCount + server.generationQueue.queuedCount, 8)
	}

	private var selectedVoiceProfileName: String {
		server.overview.defaultVoiceProfileName ?? server.voiceProfiles.first?.profileName ?? ""
	}

	private var selectedBackend: SpeakSwiftly.SpeechBackend {
		SpeakSwiftly.SpeechBackend.normalized(
			rawValue: server.runtimeConfiguration.activeRuntimeSpeechBackend,
		) ?? .qwen3
	}

	private var powerSymbolName: String {
		server.overview.workerStage == "resident_models_unloaded" ? "power.circle" : "power.circle.fill"
	}

	private var playbackSymbolName: String {
		switch server.playback.state {
			case "playing":
				"pause.fill"
			case "paused":
				"play.fill"
			default:
				"clipboard"
		}
	}

	// MARK: Main View Body

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			MenuHeaderComponent(
				headline: statusHeadline,
				detail: statusDetail,
			)

			QueueCountComponent(
				filledSlotCount: queueSlotCount,
				totalSlotCount: 8,
				label: "Queue",
			)

			MenuControlGroupComponent(

				powerSymbolName: powerSymbolName,
				playbackSymbolName: playbackSymbolName,
				isPowerButtonDisabled: isRunningModelAction,
				isPlaybackButtonDisabled: isSubmittingClipboardSpeech,
				powerAction: toggleResidentModels,
				playbackAction: handlePlaybackButton,
				openSettingsAction: { openSettings() },
			)

			MenuPickerComponent(
				selectedVoiceProfileName: Binding(
					get: { selectedVoiceProfileName },
					set: { newValue in
						handleVoiceSelection(newValue)
					},
				),
				selectedBackend: Binding(
					get: { selectedBackend },
					set: { newValue in
						handleBackendSelection(newValue)
					},
				),
				voiceProfiles: server.voiceProfiles,
				availableBackends: SpeakSwiftly.SpeechBackend.allCases,
				isVoicePickerDisabled: server.voiceProfiles.isEmpty || isRunningVoiceAction,
				isBackendPickerDisabled: isRunningBackendAction,
			)
		}
		.padding(14)
		.frame(width: 320)
		.accessibilityIdentifier("saybar-menu-window")
		.task {
			await refreshVoiceProfilesIfNeeded()
		}
	}
}

private extension MenuBarExtraWindow {
	@MainActor
	func refreshVoiceProfilesIfNeeded() async {
		guard server.voiceProfiles.isEmpty else {
			return
		}

		do {
			isRunningVoiceAction = true
			_ = try await server.refreshVoiceProfiles()
		} catch {
			handleActionError(
				error,
				fallbackMessage: "SayBar could not refresh the embedded voice profile list for the menu bar.",
			)
		}

		isRunningVoiceAction = false
	}

	@MainActor
	func toggleResidentModels() {
		Task { @MainActor in
			isRunningModelAction = true
			do {
				if server.overview.workerStage == "resident_models_unloaded" {
					_ = try await server.reloadModels()
					actionMessage = "Resident models are loaded again."
				} else {
					_ = try await server.unloadModels()
					actionMessage = "Resident models are unloaded."
				}
			} catch {
				handleActionError(
					error,
					fallbackMessage: "SayBar could not change the resident model state.",
				)
			}
			isRunningModelAction = false
		}
	}

	@MainActor
	func handlePlaybackButton() {
		Task { @MainActor in
			switch server.playback.state {
				case "playing":
					do {
						_ = try await server.pausePlayback()
						actionMessage = "Playback is paused."
					} catch {
						handleActionError(
							error,
							fallbackMessage: "SayBar could not pause playback.",
						)
					}
				case "paused":
					do {
						_ = try await server.resumePlayback()
						actionMessage = "Playback resumed."
					} catch {
						handleActionError(
							error,
							fallbackMessage: "SayBar could not resume playback.",
						)
					}
				default:
					await submitClipboardSpeech()
			}
		}
	}

	@MainActor
	func submitClipboardSpeech() async {
		let pastedText = NSPasteboard.general.string(forType: .string)?
			.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

		guard !pastedText.isEmpty else {
			actionMessage = "The clipboard does not contain text to speak."
			return
		}

		isSubmittingClipboardSpeech = true
		defer { isSubmittingClipboardSpeech = false }

		do {
			_ = try await server.queueLiveSpeech(text: pastedText)
			actionMessage = "Queued clipboard text for live speech."
		} catch {
			handleActionError(
				error,
				fallbackMessage: "SayBar could not queue clipboard text for live speech.",
			)
		}
	}

	@MainActor
	func handleVoiceSelection(_ profileName: String) {
		Task { @MainActor in
			guard !profileName.isEmpty else {
				return
			}

			isRunningVoiceAction = true
			do {
				let resolvedProfileName = try await server.setDefaultVoiceProfileName(profileName)
				actionMessage = "Default voice profile set to \(resolvedProfileName)."
			} catch {
				handleActionError(
					error,
					fallbackMessage: "SayBar could not set the default voice profile.",
				)
			}
			isRunningVoiceAction = false
		}
	}

	@MainActor
	func handleBackendSelection(_ backend: SpeakSwiftly.SpeechBackend) {
		Task { @MainActor in
			isRunningBackendAction = true
			do {
				_ = try await server.switchSpeechBackend(to: backend)
				actionMessage = "Speech backend switched to \(backend.rawValue)."
			} catch {
				handleActionError(
					error,
					fallbackMessage: "SayBar could not switch the active speech backend.",
				)
			}
			isRunningBackendAction = false
		}
	}

	@MainActor
	func handleActionError(_ error: Error, fallbackMessage: String) {
		let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
		actionMessage = message.isEmpty ? fallbackMessage : message
		Self.logger.error("\(fallbackMessage, privacy: .public) Likely cause: \(message, privacy: .public)")
	}
}

private struct MenuHeaderComponent: View {
	let headline: String
	let detail: String

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(headline)
				.font(.headline)
				.accessibilityIdentifier("saybar-status-headline")
			Text(detail)
				.font(.caption)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
				.accessibilityIdentifier("saybar-status-detail")
		}
	}
}

private struct QueueCountComponent: View {
	let filledSlotCount: Int
	let totalSlotCount: Int
	let label: String

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("\(label): \(filledSlotCount) of \(totalSlotCount)")
				.font(.caption)
				.foregroundStyle(.secondary)
			HStack(alignment: .center, spacing: 6) {
				ForEach(0..<totalSlotCount, id: \.self) { index in
					QueueSlotShape(isFilled: index < filledSlotCount)
				}
			}
		}
	}
}

private struct QueueSlotShape: View {
	let isFilled: Bool

	var body: some View {
		Rectangle()
			.fill(isFilled ? Color.accentColor : .clear)
			.overlay {
				Rectangle()
					.stroke(Color.accentColor, lineWidth: 1)
			}
			.frame(width: 32, height: 40)
			.accessibilityHidden(true)
	}
}

private struct MenuControlGroupComponent: View {

	let powerSymbolName: String
	let playbackSymbolName: String
	let isPowerButtonDisabled: Bool
	let isPlaybackButtonDisabled: Bool
	let powerAction: () -> Void
	let playbackAction: () -> Void
	let openSettingsAction: () -> Void

	var body: some View {
		ControlGroup {
			HStack(alignment: .center, spacing: 20) {
					Button(action: powerAction) {
						Image(systemName: powerSymbolName)
					}
					.disabled(isPowerButtonDisabled)
					.buttonStyle(.bordered)

					Button(action: playbackAction) {
						Image(systemName: playbackSymbolName)
					}
					.disabled(isPlaybackButtonDisabled)
					.buttonStyle(.bordered)

					Button(action: openSettingsAction) {
						Image(systemName: "gear")
					}
					.buttonStyle(.bordered)
					.accessibilityIdentifier("saybar-open-settings")
				}
		}
	}
}

private struct MenuPickerComponent: View {

	@Binding var selectedVoiceProfileName: String
	@Binding var selectedBackend: SpeakSwiftly.SpeechBackend

	let voiceProfiles: [ProfileSnapshot]
	let availableBackends: [SpeakSwiftly.SpeechBackend]
	let isVoicePickerDisabled: Bool
	let isBackendPickerDisabled: Bool

	var body: some View {
		HStack(alignment: .center) {
			Picker("Voice Profile", selection: $selectedVoiceProfileName) {
				ForEach(voiceProfiles, id: \.profileName) { profile in
					Text(profile.profileName).tag(profile.profileName)
				}
			}
			.labelsHidden()
			.pickerStyle(.menu)
			.frame(maxWidth: .infinity)
			.disabled(isVoicePickerDisabled)

			Picker("Speech Backend", selection: $selectedBackend) {
				ForEach(availableBackends, id: \.self) { backend in
					Text(backend.rawValue).tag(backend)
				}
			}
			.labelsHidden()
			.pickerStyle(.menu)
			.frame(maxWidth: .infinity)
			.disabled(isBackendPickerDisabled)
		}
	}
}

#Preview {
	MenuBarExtraWindow(
		server: EmbeddedServer(),
		autostartEnabled: false,
	)
}
