//
//  MenuBarExtraWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI

struct MenuBarExtraWindow: View {
	@Environment(\.openSettings)
	private var openSettings

	let ssController: SpeakSwiftlyController

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			MenuBarStatusHeader(
				symbolName: ssController.menuBarSymbolName,
				serviceState: ssController.serviceState,
				headline: ssController.statusHeadline,
				detail: ssController.statusDetail
			)

			Divider()

			if let metrics = ssController.menuMetrics {
				MenuBarMetricsSection(metrics: metrics)
			}

			MenuBarServiceControls(
				primaryActionTitle: ssController.primaryActionTitle,
				canRestart: ssController.canRestart,
				canStop: ssController.canStop,
				startOrRestart: {
					if ssController.canStart {
						await ssController.startIfNeeded()
					} else {
						await ssController.restart()
					}
				},
				stop: {
					await ssController.stopIfRunning()
				}
			)

			if ssController.canPausePlayback || ssController.canResumePlayback || ssController.canClearPlaybackQueue {
				MenuBarPlaybackControls(
					canPausePlayback: ssController.canPausePlayback,
					canResumePlayback: ssController.canResumePlayback,
					canClearPlaybackQueue: ssController.canClearPlaybackQueue,
					playbackActionTitle: ssController.canResumePlayback ? "Resume Playback" : "Pause Playback",
					playbackAction: {
						if ssController.canResumePlayback {
							await ssController.resumePlayback()
						} else {
							await ssController.pausePlayback()
						}
					},
					clearQueue: {
						await ssController.clearPlaybackQueue()
					}
				)
			}

			MenuBarSettingsButton {
				openSettings()
			}
		}
		.padding(16)
		.frame(width: 340, alignment: .leading)
		.accessibilityIdentifier("saybar-menu-window")
	}
}

private struct MenuBarStatusHeader: View {
	let symbolName: String
	let serviceState: SpeakSwiftlyController.ServiceState
	let headline: String
	let detail: String

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: symbolName)
				.font(.title2)
				.symbolRenderingMode(.hierarchical)
				.foregroundStyle(statusTint)
				.accessibilityIdentifier("saybar-status-icon")

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

	private var statusTint: Color {
		switch serviceState {
		case .stopped:
			.secondary
		case .starting:
			.orange
		case .ready:
			.green
		case .degraded:
			.yellow
		case .broken:
			.red
		}
	}
}

private struct MenuBarMetricsSection: View {
	let metrics: SpeakSwiftlyController.MenuMetrics

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			ForEach(metrics.rows) { row in
				LabeledContent(row.title, value: row.value)
					.font(.caption)
			}
		}
	}
}

private struct MenuBarServiceControls: View {
	let primaryActionTitle: String
	let canRestart: Bool
	let canStop: Bool
	let startOrRestart: @MainActor () async -> Void
	let stop: @MainActor () async -> Void

	var body: some View {
		ControlGroup {
			Button(primaryActionTitle) {
				Task {
					await startOrRestart()
				}
			}
			.disabled(!canRestart)
			.accessibilityIdentifier("saybar-primary-action")

			Button("Stop") {
				Task {
					await stop()
				}
			}
			.disabled(!canStop)
			.accessibilityIdentifier("saybar-stop")
		}
	}
}

private struct MenuBarPlaybackControls: View {
	let canPausePlayback: Bool
	let canResumePlayback: Bool
	let canClearPlaybackQueue: Bool
	let playbackActionTitle: String
	let playbackAction: @MainActor () async -> Void
	let clearQueue: @MainActor () async -> Void

	var body: some View {
		ControlGroup {
			Button(playbackActionTitle) {
				Task {
					await playbackAction()
				}
			}
			.disabled(!canPausePlayback && !canResumePlayback)
			.accessibilityIdentifier("saybar-playback-action")

			Button("Clear Queue") {
				Task {
					await clearQueue()
				}
			}
			.disabled(!canClearPlaybackQueue)
			.accessibilityIdentifier("saybar-clear-queue")
		}
		.font(.caption)
	}
}

private struct MenuBarSettingsButton: View {
	let openSettings: () -> Void

	var body: some View {
		Button("Open Settings", action: openSettings)
			.font(.caption)
			.accessibilityIdentifier("saybar-open-settings")
	}
}

#Preview {
	MenuBarExtraWindow(ssController: SpeakSwiftlyController(autoStart: false))
}
