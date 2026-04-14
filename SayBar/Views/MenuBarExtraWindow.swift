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
					.accessibilityIdentifier("saybar-status-icon")

				VStack(alignment: .leading, spacing: 4) {
					Text(ssController.statusHeadline)
						.font(.headline)
						.accessibilityIdentifier("saybar-status-headline")

					Text(ssController.statusDetail)
						.font(.caption)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
						.accessibilityIdentifier("saybar-status-detail")
				}
			}

			Divider()

			if let metrics = ssController.menuMetrics {
				VStack(alignment: .leading, spacing: 6) {
					ForEach(metrics.rows) { row in
						HStack(alignment: .firstTextBaseline, spacing: 12) {
							Text(row.title)
								.font(.caption)
								.foregroundStyle(.secondary)
							Text(row.value)
								.font(.caption.weight(.medium))
						}
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
				.buttonStyle(.plain)
				.disabled(!ssController.canRestart)
				.accessibilityIdentifier("saybar-primary-action")

				Button("Stop") {
					Task {
						await ssController.stopIfRunning()
					}
				}
				.buttonStyle(.plain)
				.disabled(!ssController.canStop)
				.accessibilityIdentifier("saybar-stop")
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
					.buttonStyle(.plain)
					.disabled(!ssController.canPausePlayback && !ssController.canResumePlayback)
					.accessibilityIdentifier("saybar-playback-action")

					Button("Clear Queue") {
						Task {
							await ssController.clearPlaybackQueue()
						}
					}
					.buttonStyle(.plain)
					.disabled(!ssController.canClearPlaybackQueue)
					.accessibilityIdentifier("saybar-clear-queue")
				}
				.font(.caption)
			}

			Button("Open Settings") {
				openSettings()
			}
			.buttonStyle(.plain)
			.font(.caption)
			.accessibilityIdentifier("saybar-open-settings")
		}
		.padding(16)
		.frame(width: 340, alignment: .leading)
		.accessibilityIdentifier("saybar-menu-window")
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
}

#Preview {
    MenuBarExtraWindow(ssController: SpeakSwiftlyController(autoStart: false))
}
