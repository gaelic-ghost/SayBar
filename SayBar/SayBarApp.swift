//
//  SayBarApp.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import OSLog
import SpeakSwiftlyServer
import SwiftUI

@main
struct SayBarApp: App {
	@AppStorage("showMenuBarExtra")
	private var isInserted: Bool = true

	private let server: EmbeddedServer
	private let autostartEnabled: Bool
	private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "app")

	init() {
		let launchArguments = ProcessInfo.processInfo.arguments
		let autostartEnabled = !launchArguments.contains("--saybar-disable-autostart")
		self.autostartEnabled = autostartEnabled
		self.server = EmbeddedServer(
			options: .init(
				port: 7339,
				runtimeProfileRootURL: Self.runtimeProfileRootURL(),
			),
		)

		guard autostartEnabled else {
			return
		}

		let server = self.server
		Task { @MainActor in
			do {
				try await server.liftoff()
				_ = try? await server.refreshVoiceProfiles()
			} catch {
				Self.logger.error("SayBar could not start the embedded SpeakSwiftlyServer runtime during app launch. Likely cause: \(error.localizedDescription)")
			}
		}
	}

	var body: some Scene {
		MenuBarExtra(isInserted: $isInserted) {
			MenuBarExtraWindow(
				server: server,
				autostartEnabled: autostartEnabled,
			)
		} label: {
			Label("SayBar", systemImage: "waveform.and.mic")
				.labelStyle(.iconOnly)
				.accessibilityLabel("SayBar")
				.accessibilityIdentifier("saybar-menu-bar-extra")
		}
		.menuBarExtraStyle(.window)

		Settings {
			SettingsWindow(
				server: server,
				autostartEnabled: autostartEnabled,
				isMenuBarExtraInserted: $isInserted,
			)
		}
	}
}

private extension SayBarApp {
	static func runtimeProfileRootURL(fileManager: FileManager = .default) -> URL? {
		fileManager
			.urls(for: .applicationSupportDirectory, in: .userDomainMask)
			.first?
			.appendingPathComponent("SayBar/SpeakSwiftlyRuntime", isDirectory: true)
	}
}
