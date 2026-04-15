//
//  SayBarApp.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI

@main
struct SayBarApp: App {
	@AppStorage("showMenuBarExtra")
	private var isInserted: Bool = true

	@State
	private var ssController = SpeakSwiftlyController(
		autoStart: !ProcessInfo.processInfo.arguments.contains("--saybar-disable-autostart")
	)

	var body: some Scene {
		MenuBarExtra(isInserted: $isInserted) {
			MenuBarExtraWindow(ssController: ssController)
		} label: {
			Label("SayBar", systemImage: ssController.menuBarSymbolName)
				.labelStyle(.iconOnly)
				.accessibilityLabel("SayBar")
				.accessibilityIdentifier("saybar-menu-bar-extra")
		}
		.menuBarExtraStyle(.window)

		Settings {
			SettingsWindow(ssController: ssController)
		}
	}
}
