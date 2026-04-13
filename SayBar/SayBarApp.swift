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
	private var ssController = SpeakSwiftlyController()

		// MARK: Scene Body

    var body: some Scene {

			// MARK: macOS Menu Bar Scene

		MenuBarExtra(
			"SayBar",
			systemImage: ssController.menuBarSymbolName,
			isInserted: $isInserted
		) {
			MenuBarExtraWindow(ssController: ssController)
		}
		.menuBarExtraStyle(.window)

			// MARK: macOS Settings Scene

		Settings {
			SettingsWindow(ssController: ssController)
		}
    }
}
