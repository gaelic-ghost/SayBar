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

	@AppStorage(Self.embeddedRuntimeAutostartKey)
	private var embeddedRuntimeAutostartEnabled: Bool = true

	private let runtimeAutostartEnabledForLaunch: Bool
	private let settingsDisplayStateOverride: SettingsDisplayState?
	private static let logger = Logger(subsystem: "com.galewilliams.SayBar", category: "app")
	private static let embeddedRuntimeAutostartKey = "embeddedRuntimeAutostartEnabled"

	init() {
		let launchArguments = ProcessInfo.processInfo.arguments
		let autostartDisabledForLaunch = SayBarAppEnvironment.autostartDisabledForLaunch(for: launchArguments)
		let persistedAutostartEnabled = SayBarAppEnvironment.persistedEmbeddedRuntimeAutostartEnabled(
			defaults: .standard,
			key: Self.embeddedRuntimeAutostartKey
		)
		let runtimeAutostartEnabledForLaunch = persistedAutostartEnabled && !autostartDisabledForLaunch
		let settingsDisplayStateOverride = SayBarAppEnvironment.settingsDisplayStateOverride(for: launchArguments)
		let server = EmbeddedServer(
			options: .init(
				port: 7339,
				runtimeProfileRootURL: SayBarAppEnvironment.runtimeProfileRootURL(),
			),
		)

		self.runtimeAutostartEnabledForLaunch = runtimeAutostartEnabledForLaunch
		self.settingsDisplayStateOverride = settingsDisplayStateOverride
		_server = State(initialValue: server)
		SayBarTerminationCoordinator.shared.configure(
			server: server,
			autostartEnabled: runtimeAutostartEnabledForLaunch,
		)

		Task { @MainActor in
			_ = await SayBarAppLifecycleSupport.startEmbeddedRuntimeIfNeeded(
				autostartEnabled: runtimeAutostartEnabledForLaunch,
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
				autostartEnabled: runtimeAutostartEnabledForLaunch,
			)
		} label: {
			Label("SayBar", systemImage: "waveform.and.mic")
				.labelStyle(.iconOnly)
				.accessibilityLabel("SayBar")
				.accessibilityIdentifier("saybar-menu-bar-extra")
		}
		.menuBarExtraStyle(.window)

		Settings {
			if let settingsDisplayStateOverride {
				SettingsWindow(
					displayState: settingsDisplayStateOverride,
					embeddedRuntimeAutostartEnabled: $embeddedRuntimeAutostartEnabled,
					isMenuBarExtraInserted: $isInserted,
				)
			} else {
				SettingsWindow(
					server: server,
					embeddedRuntimeAutostartEnabled: $embeddedRuntimeAutostartEnabled,
					isMenuBarExtraInserted: $isInserted,
				)
			}
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
	static func autostartDisabledForLaunch(for launchArguments: [String]) -> Bool {
		launchArguments.contains("--saybar-disable-autostart")
	}

	static func persistedEmbeddedRuntimeAutostartEnabled(
		defaults: UserDefaults,
		key: String
	) -> Bool {
		defaults.object(forKey: key) as? Bool ?? true
	}

	static func settingsDisplayStateOverride(for launchArguments: [String]) -> SettingsDisplayState? {
		guard launchArguments.contains("--saybar-ui-fixture-populated-settings") else {
			return nil
		}

		return SettingsDisplayState.uiTestPopulatedFixture(buildVersion: "UI Test Fixture")
	}

	static func runtimeProfileRootURL(fileManager: FileManager = .default) -> URL? {
		fileManager
			.urls(for: .applicationSupportDirectory, in: .userDomainMask)
			.first?
			.appendingPathComponent("SayBar/SpeakSwiftlyRuntime", isDirectory: true)
	}
}
