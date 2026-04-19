//
//  SettingsWindow.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import SwiftUI
import SpeakSwiftlyServer

struct SettingsWindow: View {
	@AppStorage("showMenuBarExtra")
	private var isInserted: Bool = true

	var body: some View {
		Form {

		}
	}
}

#Preview {
	SettingsWindow()
}
