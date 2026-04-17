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
				serviceState: ssController.serviceState,
				headline: ssController.statusHeadline,
				detail: ssController.statusDetail
			)

			if let metrics = ssController.menuMetrics {
				MenuBarQuickStatus(metrics: metrics)
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

			HStack {
				MenuBarSettingsButton {
					openSettings()
				}

				Spacer()

				Image(systemName: ssController.menuBarSymbolName)
					.font(.caption)
					.foregroundStyle(.secondary)
					.accessibilityHidden(true)
			}
		}
		.padding(16)
		.frame(width: 340, alignment: .leading)
		.accessibilityIdentifier("saybar-menu-window")
	}
}

private struct MenuBarStatusHeader: View {
	let serviceState: SpeakSwiftlyController.ServiceState
	let headline: String
	let detail: String

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 8) {
				Circle()
					.fill(statusTint)
					.frame(width: 10, height: 10)
					.accessibilityIdentifier("saybar-status-icon")

				Text(serviceState.displayName)
					.font(.caption.weight(.semibold))
					.foregroundStyle(statusTint)

				Spacer()

				Text("Embedded Session")
					.font(.caption)
					.foregroundStyle(.secondary)
			}

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

	private var statusTint: Color {
		switch serviceState {
		case .ready:
			greenStatus
		case .starting, .degraded:
			yellowStatus
		case .stopped, .broken:
			redStatus
		}
	}

	private var greenStatus: Color {
		Color(nsColor: .systemGreen)
	}

	private var yellowStatus: Color {
		Color(nsColor: .systemYellow)
	}

	private var redStatus: Color {
		Color(nsColor: .systemRed)
	}
}

private struct MenuBarQuickStatus: View {
	let metrics: SpeakSwiftlyController.MenuMetrics

	var body: some View {
		HStack(spacing: 10) {
			ForEach(metrics.rows.prefix(3)) { row in
				VStack(alignment: .leading, spacing: 2) {
					Text(row.title)
						.font(.caption2)
						.foregroundStyle(.secondary)

					Text(row.value)
						.font(.caption.weight(.medium))
						.lineLimit(1)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, 10)
				.padding(.vertical, 8)
				.background {
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.fill(.quaternary.opacity(0.35))
				}
			}
		}
	}
}

private struct MenuBarSectionLabel: View {
	let title: String

	var body: some View {
		Text(title)
			.font(.caption.weight(.semibold))
			.foregroundStyle(.secondary)
			.textCase(.uppercase)
	}
}

private struct MenuBarActionButtonStyle: ButtonStyle {
	let isPrimary: Bool

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.caption.weight(.semibold))
			.frame(maxWidth: .infinity)
			.padding(.vertical, 8)
			.background(backgroundColor(configuration: configuration), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
			.foregroundStyle(foregroundColor)
			.opacity(configuration.isPressed ? 0.88 : 1)
	}

	private func backgroundColor(configuration: Configuration) -> Color {
		if isPrimary {
			return Color.accentColor.opacity(configuration.isPressed ? 0.78 : 1)
		}

		return Color.secondary.opacity(configuration.isPressed ? 0.16 : 0.12)
	}

	private var foregroundColor: Color {
		isPrimary ? .white : .primary
	}
}

private struct MenuBarServiceControls: View {
	let primaryActionTitle: String
	let canRestart: Bool
	let canStop: Bool
	let startOrRestart: @MainActor () async -> Void
	let stop: @MainActor () async -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			MenuBarSectionLabel(title: "Service")

			HStack(spacing: 10) {
				Button(primaryActionTitle) {
					Task {
						await startOrRestart()
					}
				}
				.buttonStyle(MenuBarActionButtonStyle(isPrimary: true))
				.disabled(!canRestart)
				.accessibilityIdentifier("saybar-primary-action")

				Button("Stop") {
					Task {
						await stop()
					}
				}
				.buttonStyle(MenuBarActionButtonStyle(isPrimary: false))
				.disabled(!canStop)
				.accessibilityIdentifier("saybar-stop")
			}
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
		VStack(alignment: .leading, spacing: 8) {
			MenuBarSectionLabel(title: "Playback")

			HStack(spacing: 10) {
				Button(playbackActionTitle) {
					Task {
						await playbackAction()
					}
				}
				.buttonStyle(MenuBarActionButtonStyle(isPrimary: false))
				.disabled(!canPausePlayback && !canResumePlayback)
				.accessibilityIdentifier("saybar-playback-action")

				Button("Clear Queue") {
					Task {
						await clearQueue()
					}
				}
				.buttonStyle(MenuBarActionButtonStyle(isPrimary: false))
				.disabled(!canClearPlaybackQueue)
				.accessibilityIdentifier("saybar-clear-queue")
			}
		}
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
