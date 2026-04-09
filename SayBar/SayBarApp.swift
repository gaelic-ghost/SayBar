//
//  SayBarApp.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI
import SwiftData

@main
struct SayBarApp: App {

	// MARK: App State

	@State private var isInserted: Bool = true

	// MARK: Scene Body

    var body: some Scene {
		MenuBarExtra(
			"Title Label",
			systemImage: "SFSymbol String",
			isInserted: $isInserted
		) {
			MenuBarExtraWindow()
		}
		.menuBarExtraStyle(.window)
		Settings {
			SettingsWindow()
		}
    }
}
