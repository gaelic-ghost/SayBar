//
//  SettingsWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI
import SpeakSwiftlyServer

struct SettingsWindow: View {
	@AppStorage("showMenuBarExtra")
	private var isInserted: Bool = true

	let ssController: SpeakSwiftlyController

	var body: some View {
		Form {
			SettingsStatusSection(ssController: ssController)
			GeneralSettingsSection(
				isInserted: $isInserted,
				autoStartEnabled: ssController.autoStartEnabled
			)
			RuntimeSettingsSection(serverState: ssController.serverState)
			PlaybackSettingsSection(ssController: ssController)
			TransportSettingsSection(ssController: ssController)
			DiagnosticsSettingsSection(ssController: ssController)
		}
		.frame(minWidth: 460, minHeight: 520)
	}
}

private struct SettingsStatusSection: View {
	let ssController: SpeakSwiftlyController

	var body: some View {
		Section("Service") {
			Text(ssController.statusHeadline)
				.font(.headline)

			Text(ssController.statusDetail)
				.font(.callout)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)

			ControlGroup {
				Button(ssController.primaryActionTitle) {
					Task {
						if ssController.canStart {
							await ssController.startIfNeeded()
						} else {
							await ssController.restart()
						}
					}
				}
				.disabled(!ssController.canRestart)

				Button("Stop") {
					Task {
						await ssController.stopIfRunning()
					}
				}
				.disabled(!ssController.canStop)
			}
		}
	}
}

private struct GeneralSettingsSection: View {
	@Binding var isInserted: Bool
	let autoStartEnabled: Bool

	var body: some View {
		Section("General") {
			Toggle("Show SayBar in the menu bar", isOn: $isInserted)

			Text(autoStartEnabled
				? "SayBar is currently configured to start the embedded SpeakSwiftlyServer session automatically when the app launches."
				: "SayBar is currently configured to wait for a manual embedded-session start.")
				.font(.caption)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
		}
	}
}

private struct RuntimeSettingsSection: View {
	let serverState: ServerState?

	var body: some View {
		Section("Runtime") {
			if let state = serverState {
				LabeledContent("Server Mode", value: state.overview.serverMode)
				LabeledContent("Worker Mode", value: state.overview.workerMode)
				LabeledContent("Worker Stage", value: state.overview.workerStage)
				LabeledContent("Worker Ready", value: state.overview.workerReady ? "Yes" : "No")
				LabeledContent("Profile Cache", value: state.overview.profileCacheState)
				LabeledContent("Profile Count", value: "\(state.overview.profileCount)")
				LabeledContent("Speech Backend", value: state.runtimeConfiguration.activeRuntimeSpeechBackend)
			} else {
				ContentUnavailableView(
					"Runtime Details Unavailable",
					systemImage: "server.rack",
					description: Text("The embedded server has not started yet, so runtime details are not available.")
				)
			}
		}
	}
}

private struct PlaybackSettingsSection: View {
	let ssController: SpeakSwiftlyController

	var body: some View {
		Section("Playback") {
			if let state = ssController.serverState {
				LabeledContent("Playback State", value: state.playback.state)
				LabeledContent("Active Request", value: state.playback.activeRequest?.id ?? "None")
				LabeledContent("Generation Queue", value: "\(state.generationQueue.queuedCount) queued")
				LabeledContent("Playback Queue", value: "\(state.playbackQueue.queuedCount) queued")

				ControlGroup {
					Button(ssController.canResumePlayback ? "Resume Playback" : "Pause Playback") {
						Task {
							if ssController.canResumePlayback {
								await ssController.resumePlayback()
							} else {
								await ssController.pausePlayback()
							}
						}
					}
					.disabled(!ssController.canPausePlayback && !ssController.canResumePlayback)

					Button("Clear Playback Queue") {
						Task {
							await ssController.clearPlaybackQueue()
						}
					}
					.disabled(!ssController.canClearPlaybackQueue)
				}
			} else {
				ContentUnavailableView(
					"Playback Controls Unavailable",
					systemImage: "speaker.wave.2",
					description: Text("Playback controls become available once the embedded session is running.")
				)
			}
		}
	}
}

private struct TransportSettingsSection: View {
	let ssController: SpeakSwiftlyController

	var body: some View {
		Section("Transports") {
			if let state = ssController.serverState, !state.transports.isEmpty {
				ForEach(Array(state.transports.enumerated()), id: \.offset) { _, transport in
					VStack(alignment: .leading, spacing: 2) {
						Text(ssController.transportSummary(for: transport))
							.font(.callout.weight(.medium))

						Text("Enabled: \(transport.enabled ? "Yes" : "No")")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
			} else {
				ContentUnavailableView(
					"Transport State Unavailable",
					systemImage: "network",
					description: Text("The embedded session has not reported transport state yet.")
				)
			}
		}
	}
}

private struct DiagnosticsSettingsSection: View {
	let ssController: SpeakSwiftlyController

	var body: some View {
		Section("Diagnostics") {
			if let state = ssController.serverState, !state.recentErrors.isEmpty {
				ForEach(Array(state.recentErrors.enumerated()), id: \.offset) { _, error in
					VStack(alignment: .leading, spacing: 4) {
						Text(error.message)
							.font(.callout.weight(.medium))
						Text("\(error.source) • \(error.code) • \(error.occurredAt)")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
			} else if let failure = ssController.lastFailureMessage {
				Text(failure)
					.font(.callout)
					.foregroundStyle(.secondary)
			} else {
				ContentUnavailableView(
					"No Recent Errors",
					systemImage: "checkmark.circle",
					description: Text("SayBar has not recorded any recent embedded-session errors.")
				)
			}
		}
	}
}

#Preview {
	SettingsWindow(ssController: SpeakSwiftlyController(autoStart: false))
}
