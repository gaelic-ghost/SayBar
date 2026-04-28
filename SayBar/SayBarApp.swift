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

		Task { @MainActor in
			_ = await SayBarAppLifecycleSupport.startEmbeddedRuntimeIfNeeded(
				autostartEnabled: autostartEnabled,
				liftoff: {
					try await server.liftoff()
				},
				refreshVoiceProfiles: {
					_ = try await server.refreshVoiceProfiles()
				},
				logStartupError: { error in
					Self.logger.error("SayBar could not start the embedded SpeakSwiftlyServer runtime during app launch. Likely cause: \(error.localizedDescription)")
				},
			)
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
		let request = SayBarAppLifecycleSupport.terminationRequest(
			autostartEnabled: autostartEnabled,
			serverIsAvailable: server != nil,
			isTerminationInFlight: isTerminationInFlight,
		)

		switch request {
			case .terminateNow:
				return nil
			case .finishExistingTermination:
				return self
			case .startNewTermination:
				isTerminationInFlight = true
				return self
		}
	}

	func finishTermination() async {
		defer {
			isTerminationInFlight = false
		}

		guard let server else {
			NSApp.reply(toApplicationShouldTerminate: true)
			return
		}

		await SayBarAppLifecycleSupport.finishTermination(
			land: {
				try await server.land()
			},
			replyToApplicationShouldTerminate: { shouldTerminate in
				NSApp.reply(toApplicationShouldTerminate: shouldTerminate)
			},
			logTerminationError: { error in
				Self.logger.error("SayBar could not stop the embedded SpeakSwiftlyServer runtime before app termination. Likely cause: \(error.localizedDescription)")
			},
		)
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
