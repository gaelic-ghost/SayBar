//
//  SayBarApp.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI

@main
struct SayBarApp: App {

		// MARK: App State

	@AppStorage("showMenuBarExtra")
	private var isInserted: Bool = true

	@State
	private var ssController = SpeakSwiftlyController(
		autoStart: !ProcessInfo.processInfo.arguments.contains("--saybar-disable-autostart")
	)

		// MARK: Scene Body

    var body: some Scene {

			// MARK: macOS Menu Bar Scene

		MenuBarExtra(
			isInserted: $isInserted
		) {
			MenuBarExtraWindow(ssController: ssController)
		} label: {
			Label("SayBar", systemImage: ssController.menuBarSymbolName)
				.labelStyle(.iconOnly)
				.accessibilityLabel("SayBar")
				.accessibilityIdentifier("saybar-menu-bar-extra")
		}
		.menuBarExtraStyle(.window)

			// MARK: macOS Settings Scene

		Settings {
			SettingsWindow(ssController: ssController)
		}
    }
}
