//
//  SayBarUITestsLaunchTests.swift
//  SayBarUITests
//
//  Created by Gale Williams on 3/30/26.
//

import XCTest

final class SayBarUITestsLaunchTests: XCTestCase {
	private let launchTimeout: TimeInterval = 5
	private let terminationTimeout: TimeInterval = 5

	override func setUpWithError() throws {
		continueAfterFailure = false
	}

	override func tearDownWithError() throws {
		let app = XCUIApplication()
		if app.state != .notRunning {
			app.terminate()
		}
	}

	@MainActor
	private func makeApp() -> XCUIApplication {
		let app = XCUIApplication()
		app.launchArguments.append("--saybar-disable-autostart")
		return app
	}

	@MainActor
	private func launchAndWait(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
		app.launch()

		let launchedInForeground = app.wait(for: .runningForeground, timeout: launchTimeout)
		let launchedInBackground = launchedInForeground ? false : app.wait(for: .runningBackground, timeout: 2)

		XCTAssertTrue(
			launchedInForeground || launchedInBackground,
			"SayBar should relaunch successfully for UI tests when embedded autostart is disabled.",
			file: file,
			line: line,
		)
	}

	@MainActor
	func testAppCanRelaunchAfterTerminationWithoutEmbeddedAutostart() throws {
		let app = makeApp()
		launchAndWait(app)

		app.terminate()
		XCTAssertTrue(
			app.wait(for: .notRunning, timeout: terminationTimeout),
			"SayBar should fully terminate before the UI test attempts a relaunch.",
		)

		launchAndWait(app)
	}
}
