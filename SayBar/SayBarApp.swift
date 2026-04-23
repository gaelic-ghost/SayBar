//
//  SayBarApp.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import AppKit
import OSLog
import SpeakSwiftlyServer
import SwiftUI

@main
struct SayBarApp: App {
	@NSApplicationDelegateAdaptor(SayBarAppDelegate.self)
	private var appDelegate

	@State
	private var server: EmbeddedServer

	@AppStorage("showMenuBarExtra")
	private var isInserted: Bool = true

	private let autostartEnabled: Bool
	private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "app")

	init() {
		let launchArguments = ProcessInfo.processInfo.arguments
		let autostartEnabled = SayBarAppEnvironment.autostartEnabled(for: launchArguments)
		let server = EmbeddedServer(
			options: .init(
				port: 7339,
				runtimeProfileRootURL: SayBarAppEnvironment.runtimeProfileRootURL(),
			),
		)

		self.autostartEnabled = autostartEnabled
		_server = State(initialValue: server)
		SayBarTerminationCoordinator.shared.configure(
			server: server,
			autostartEnabled: autostartEnabled,
		)

		guard autostartEnabled else {
			return
		}

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

@MainActor
private final class SayBarAppDelegate: NSObject, NSApplicationDelegate {
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		guard let coordinator = SayBarTerminationCoordinator.shared.beginTermination() else {
			return .terminateNow
		}

		Task { @MainActor in
			await coordinator.finishTermination()
		}
		return .terminateLater
	}
}

@MainActor
private final class SayBarTerminationCoordinator {
	static let shared = SayBarTerminationCoordinator()

	private weak var server: EmbeddedServer?
	private var autostartEnabled = false
	private var isTerminationInFlight = false
	private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "termination")

	private init() {}

	func configure(server: EmbeddedServer, autostartEnabled: Bool) {
		self.server = server
		self.autostartEnabled = autostartEnabled
	}

	func beginTermination() -> SayBarTerminationCoordinator? {
		guard autostartEnabled, let server else {
			return nil
		}

		guard !isTerminationInFlight else {
			return self
		}

		self.server = server
		isTerminationInFlight = true
		return self
	}

	func finishTermination() async {
		defer {
			isTerminationInFlight = false
			NSApp.reply(toApplicationShouldTerminate: true)
		}

		guard let server else {
			return
		}

		do {
			try await server.land()
		} catch {
			Self.logger.error("SayBar could not stop the embedded SpeakSwiftlyServer runtime before app termination. Likely cause: \(error.localizedDescription)")
		}
	}
}

enum SayBarAppEnvironment {
	static func autostartEnabled(for launchArguments: [String]) -> Bool {
		!launchArguments.contains("--saybar-disable-autostart")
	}

	static func runtimeProfileRootURL(fileManager: FileManager = .default) -> URL? {
		fileManager
			.urls(for: .applicationSupportDirectory, in: .userDomainMask)
			.first?
			.appendingPathComponent("SayBar/SpeakSwiftlyRuntime", isDirectory: true)
	}
}
