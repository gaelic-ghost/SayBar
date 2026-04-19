//
//  SayBarApp.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI
import SpeakSwiftlyServer

@main
struct SayBarApp: App {
	@AppStorage("showMenuBarExtra")
	private var isInserted: Bool = true


	var body: some Scene {
		MenuBarExtra(isInserted: $isInserted) {
			MenuBarExtraWindow()
		} label: {
			Label("SayBar", systemImage: "")
				.labelStyle(.iconOnly)
				.accessibilityLabel("SayBar")
				.accessibilityIdentifier("saybar-menu-bar-extra")
		}
		.menuBarExtraStyle(.window)

		Settings {
			SettingsWindow()
		}
	}
}
