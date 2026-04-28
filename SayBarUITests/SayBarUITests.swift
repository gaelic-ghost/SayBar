//
//  SayBarUITests.swift
//  SayBarUITests
//
//  Created by Gale Williams on 3/30/26.
//

import XCTest

final class SayBarUITests: XCTestCase {
	private let launchTimeout: TimeInterval = 5
	private let terminationTimeout: TimeInterval = 5

	@MainActor
	private func makeApp() -> XCUIApplication {
		let app = XCUIApplication()
		app.launchArguments.append("--saybar-disable-autostart")
		return app
	}

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
	private func launchAndWait(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
		app.launch()

		let launchedInForeground = app.wait(for: .runningForeground, timeout: launchTimeout)
		let launchedInBackground = launchedInForeground ? false : app.wait(for: .runningBackground, timeout: 2)

		XCTAssertTrue(
			launchedInForeground || launchedInBackground,
			"SayBar should finish launching for UI tests even when embedded-runtime autostart is disabled.",
			file: file,
			line: line,
		)
	}

	@MainActor
	func testAppLaunchesWithoutEmbeddedAutostart() throws {
		let app = makeApp()
		launchAndWait(app)
	}

	@MainActor
	func testAppTerminatesCleanlyAfterLaunchWithoutEmbeddedAutostart() throws {
		let app = makeApp()
		launchAndWait(app)
		app.terminate()

		XCTAssertTrue(
			app.wait(for: .notRunning, timeout: terminationTimeout),
			"SayBar should terminate cleanly after a UI-test launch with embedded autostart disabled.",
		)
	}
}
