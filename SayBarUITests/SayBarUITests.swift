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
	private let menuTimeout: TimeInterval = 5

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
	private func openMenuExtra(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
		let appMenuExtra = app.descendants(matching: .any)["saybar-menu-bar-extra"]
		if appMenuExtra.waitForExistence(timeout: 2) {
			appMenuExtra.click()
			return
		}

		let systemUIServer = XCUIApplication(bundleIdentifier: "com.apple.systemuiserver")
		let systemMenuExtra = systemUIServer.descendants(matching: .any)["SayBar"]
		XCTAssertTrue(
			systemMenuExtra.waitForExistence(timeout: menuTimeout),
			"SayBar should publish a menu bar extra that UI tests can open by accessibility label.",
			file: file,
			line: line,
		)
		systemMenuExtra.click()
	}

	@MainActor
	private func assertElementExists(
		_ identifier: String,
		in app: XCUIApplication,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		XCTAssertTrue(
			app.descendants(matching: .any)[identifier].exists,
			"SayBar should expose \(identifier) through a stable accessibility identifier.",
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

	@MainActor
	func testMenuExtraExposesStableShellIdentifiers() throws {
		let app = makeApp()
		launchAndWait(app)

		XCTContext.runActivity(named: "Open menu extra") { _ in
			openMenuExtra(app)
		}

		XCTContext.runActivity(named: "Verify menu shell") { _ in
			XCTAssertTrue(
				app.descendants(matching: .any)["saybar-menu-window"].waitForExistence(timeout: menuTimeout),
				"SayBar should expose the menu window through a stable accessibility identifier.",
			)
			assertElementExists("saybar-status-headline", in: app)
			assertElementExists("saybar-status-detail", in: app)
			assertElementExists("saybar-generation-queue-summary", in: app)
			assertElementExists("saybar-resident-model-power", in: app)
			assertElementExists("saybar-playback-or-clipboard-speech", in: app)
			assertElementExists("saybar-open-settings", in: app)
			assertElementExists("saybar-menu-picker-row", in: app)
		}
	}
}
