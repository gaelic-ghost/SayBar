//
//  MenuBarExtraWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI
import SpeakSwiftlyServer

struct MenuBarExtraWindow: View {
	@Environment(\.openSettings)
	private var openSettings

	let ssController: SpeakSwiftlyController

    var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			HStack(alignment: .top, spacing: 12) {
				Image(systemName: ssController.menuBarSymbolName)
					.font(.title2)
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(statusTint)

				VStack(alignment: .leading, spacing: 4) {
					Text(ssController.statusHeadline)
						.font(.headline)

					Text(ssController.statusDetail)
						.font(.caption)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}
			}

			Divider()

			if let state = ssController.serverState {
				Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
					GridRow {
						metricLabel("Worker")
						metricValue(state.overview.workerMode)
					}
					GridRow {
						metricLabel("Playback")
						metricValue(state.playback.state)
					}
					GridRow {
						metricLabel("Generation Queue")
						metricValue("\(state.generationQueue.queuedCount) queued")
					}
					GridRow {
						metricLabel("Playback Queue")
						metricValue("\(state.playbackQueue.queuedCount) queued")
					}
				}
			}

			HStack(spacing: 8) {
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
				.buttonStyle(.bordered)
				.disabled(!ssController.canStop)
			}

			if ssController.canPausePlayback || ssController.canResumePlayback || ssController.canClearPlaybackQueue {
				HStack(spacing: 8) {
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

					Button("Clear Queue") {
						Task {
							await ssController.clearPlaybackQueue()
						}
					}
					.disabled(!ssController.canClearPlaybackQueue)
				}
				.font(.caption)
			}

			Button("Open Settings") {
				openSettings()
			}
			.font(.caption)
		}
		.padding(16)
		.frame(width: 340, alignment: .leading)
    }

	private var statusTint: Color {
		switch ssController.serviceState {
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

	@ViewBuilder
	private func metricLabel(_ title: String) -> some View {
		Text(title)
			.font(.caption)
			foregroundStyle(.secondary)
	}

	@ViewBuilder
	private func metricValue(_ value: String) -> some View {
		Text(value)
			.font(.caption.weight(.medium))
	}
}

#Preview {
    MenuBarExtraWindow(ssController: SpeakSwiftlyController(autoStart: false))
}
