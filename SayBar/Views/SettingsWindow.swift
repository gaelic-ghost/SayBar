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
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				statusSection
				generalSection
				runtimeSection
				playbackSection
				transportSection
				diagnosticsSection
			}
			.padding(20)
		}
		.frame(minWidth: 460, minHeight: 520)
    }

	private var statusSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Service")
				.font(.title3.weight(.semibold))

			Text(ssController.statusHeadline)
				.font(.headline)

			Text(ssController.statusDetail)
				.font(.callout)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)

			HStack(spacing: 10) {
				Button(ssController.primaryActionTitle) {
					Task {
						if ssController.canStart {
							await ssController.startIfNeeded()
						} else {
							await ssController.restart()
						}
					}
				}
				.buttonStyle(.borderedProminent)
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

	private var generalSection: some View {
		settingsSection("General") {
			Toggle("Show SayBar in the menu bar", isOn: $isInserted)

			Text(ssController.autoStartEnabled
				? "SayBar is currently configured to start the embedded SpeakSwiftlyServer session automatically when the app launches."
				: "SayBar is currently configured to wait for a manual embedded-session start.")
				.font(.caption)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
		}
	}

	private var runtimeSection: some View {
		settingsSection("Runtime") {
			if let state = ssController.serverState {
				settingsRow("Server Mode", state.overview.serverMode)
				settingsRow("Worker Mode", state.overview.workerMode)
				settingsRow("Worker Stage", state.overview.workerStage)
				settingsRow("Worker Ready", state.overview.workerReady ? "Yes" : "No")
				settingsRow("Profile Cache", state.overview.profileCacheState)
				settingsRow("Profile Count", "\(state.overview.profileCount)")
				settingsRow("Speech Backend", state.runtimeConfiguration.activeRuntimeSpeechBackend)
			} else {
				Text("The embedded server has not started yet, so runtime details are not available.")
					.font(.callout)
					.foregroundStyle(.secondary)
			}
		}
	}

	private var playbackSection: some View {
		settingsSection("Playback") {
			if let state = ssController.serverState {
				settingsRow("Playback State", state.playback.state)
				settingsRow("Active Request", state.playback.activeRequest?.id ?? "None")
				settingsRow("Generation Queue", "\(state.generationQueue.queuedCount) queued")
				settingsRow("Playback Queue", "\(state.playbackQueue.queuedCount) queued")

				HStack(spacing: 10) {
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
				Text("Playback controls become available once the embedded session is running.")
					.font(.callout)
					.foregroundStyle(.secondary)
			}
		}
	}

	private var transportSection: some View {
		settingsSection("Transports") {
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
				Text("The embedded session has not reported transport state yet.")
					.font(.callout)
					.foregroundStyle(.secondary)
			}
		}
	}

	private var diagnosticsSection: some View {
		settingsSection("Diagnostics") {
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
				Text("SayBar has not recorded any recent embedded-session errors.")
					.font(.callout)
					.foregroundStyle(.secondary)
			}
		}
	}

	@ViewBuilder
	private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(title)
				.font(.headline)
			content()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.bottom, 8)
	}

	@ViewBuilder
	private func settingsRow(_ label: String, _ value: String) -> some View {
		HStack(alignment: .firstTextBaseline) {
			Text(label)
				.foregroundStyle(.secondary)
			Spacer()
			Text(value)
				.multilineTextAlignment(.trailing)
		}
		.font(.callout)
	}
}

#Preview {
    SettingsWindow(ssController: SpeakSwiftlyController(autoStart: false))
}
