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
	private var selectedVoiceProfileName = ""

	@State
	private var selectedBackend: SpeakSwiftly.SpeechBackend = .qwen3

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

	private var header: MenuBarHeaderPresentation {
		makeMenuBarHeaderPresentation(
			overview: server.overview,
			playback: server.playback,
			recentErrors: server.recentErrors,
			actionMessage: actionMessage,
			autostartEnabled: autostartEnabled,
		)
	}

	private var queueSlotCount: Int {
		min(server.generationQueue.activeCount + server.generationQueue.queuedCount, 8)
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

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			MenuHeaderComponent(
				headline: header.headline,
				detail: header.detail,
			)

			QueueCountComponent(
				filledSlotCount: queueSlotCount,
				totalSlotCount: 8,
				label: "Queue",
			)

			MenuControlGroupComponent(
				selectedVoiceProfileName: $selectedVoiceProfileName,
				selectedBackend: $selectedBackend,
				voiceProfiles: server.voiceProfiles,
				availableBackends: SpeakSwiftly.SpeechBackend.allCases,
				powerSymbolName: powerSymbolName,
				playbackSymbolName: playbackSymbolName,
				isVoicePickerDisabled: server.voiceProfiles.isEmpty || isRunningVoiceAction,
				isBackendPickerDisabled: isRunningBackendAction,
				isPowerButtonDisabled: isRunningModelAction,
				isPlaybackButtonDisabled: isSubmittingClipboardSpeech,
				powerAction: toggleResidentModels,
				playbackAction: handlePlaybackButton,
				openSettingsAction: { openSettings() },
				voiceSelectionAction: handleVoiceSelection,
				backendSelectionAction: handleBackendSelection,
			)
		}
		.padding(14)
		.frame(width: 320)
		.accessibilityIdentifier("saybar-menu-window")
		.task {
			await syncSelectionState()
			await refreshVoiceProfilesIfNeeded()
		}
		.onChange(of: server.overview.defaultVoiceProfileName) { _, _ in
			Task { @MainActor in
				await syncSelectionState()
			}
		}
		.onChange(of: server.runtimeConfiguration.activeRuntimeSpeechBackend) { _, _ in
			Task { @MainActor in
				await syncSelectionState()
			}
		}
	}
}

private extension MenuBarExtraWindow {
	@MainActor
	func syncSelectionState() async {
		if let defaultVoiceProfileName = server.overview.defaultVoiceProfileName {
			selectedVoiceProfileName = defaultVoiceProfileName
		} else if selectedVoiceProfileName.isEmpty, let firstProfileName = server.voiceProfiles.first?.profileName {
			selectedVoiceProfileName = firstProfileName
		}

		selectedBackend = SpeakSwiftly.SpeechBackend.normalized(
			rawValue: server.runtimeConfiguration.activeRuntimeSpeechBackend,
		) ?? .qwen3
	}

	@MainActor
	func refreshVoiceProfilesIfNeeded() async {
		guard server.voiceProfiles.isEmpty else {
			return
		}

		do {
			isRunningVoiceAction = true
			_ = try await server.refreshVoiceProfiles()
			await syncSelectionState()
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
			try await EmbeddedServerLiveSpeechClient().queueClipboardSpeech(
				text: pastedText,
				server: server,
			)
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
				selectedVoiceProfileName = resolvedProfileName
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
				selectedBackend = backend
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
			HStack(spacing: 4) {
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
			.frame(width: 16, height: 10)
			.accessibilityHidden(true)
	}
}

private struct MenuControlGroupComponent: View {
	@Binding var selectedVoiceProfileName: String
	@Binding var selectedBackend: SpeakSwiftly.SpeechBackend

	let voiceProfiles: [ProfileSnapshot]
	let availableBackends: [SpeakSwiftly.SpeechBackend]
	let powerSymbolName: String
	let playbackSymbolName: String
	let isVoicePickerDisabled: Bool
	let isBackendPickerDisabled: Bool
	let isPowerButtonDisabled: Bool
	let isPlaybackButtonDisabled: Bool
	let powerAction: () -> Void
	let playbackAction: () -> Void
	let openSettingsAction: () -> Void
	let voiceSelectionAction: (String) -> Void
	let backendSelectionAction: (SpeakSwiftly.SpeechBackend) -> Void

	var body: some View {
		ControlGroup {
			VStack(alignment: .leading, spacing: 10) {
				HStack(spacing: 10) {
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

				HStack(spacing: 10) {
					Picker("Voice Profile", selection: $selectedVoiceProfileName) {
						ForEach(voiceProfiles, id: \.profileName) { profile in
							Text(profile.profileName).tag(profile.profileName)
						}
					}
					.labelsHidden()
					.pickerStyle(.menu)
					.frame(maxWidth: .infinity)
					.disabled(isVoicePickerDisabled)
					.onChange(of: selectedVoiceProfileName) { _, newValue in
						voiceSelectionAction(newValue)
					}

					Picker("Speech Backend", selection: $selectedBackend) {
						ForEach(availableBackends, id: \.self) { backend in
							Text(backend.rawValue).tag(backend)
						}
					}
					.labelsHidden()
					.pickerStyle(.menu)
					.frame(maxWidth: .infinity)
					.disabled(isBackendPickerDisabled)
					.onChange(of: selectedBackend) { _, newValue in
						backendSelectionAction(newValue)
					}
				}
			}
		}
	}
}

#Preview {
	MenuBarExtraWindow(
		server: EmbeddedServer(),
		autostartEnabled: false,
	)
}
