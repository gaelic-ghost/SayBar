//
//  SayBarUITests.swift
//  SayBarUITests
//
//  Created by Gale Williams on 3/30/26.
//

import XCTest

final class SayBarUITests: XCTestCase {

	@MainActor private func makeApp() -> XCUIApplication {
		let app = XCUIApplication()
		app.launchArguments.append("--saybar-disable-autostart")
		return app
	}

	override func setUpWithError() throws {
		continueAfterFailure = false
	}

	override func tearDownWithError() throws {}

	@MainActor
	func testAppLaunchesWithoutEmbeddedAutostart() throws {
		let app = makeApp()
		app.launch()

		let launchedInForeground = app.wait(for: .runningForeground, timeout: 5)
		let launchedInBackground = launchedInForeground ? false : app.wait(for: .runningBackground, timeout: 2)

		XCTAssertTrue(
			launchedInForeground || launchedInBackground,
			"SayBar should finish launching for UI tests even when embedded-session autostart is disabled."
		)
	}

	@MainActor
	func testLaunchPerformance() throws {
		measure(metrics: [XCTApplicationLaunchMetric()]) {
			makeApp().launch()
		}
	}
}
