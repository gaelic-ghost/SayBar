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
	private func makeApp(additionalLaunchArguments: [String] = []) -> XCUIApplication {
		let app = XCUIApplication()
		app.launchArguments.append("--saybar-disable-autostart")
		app.launchArguments.append(contentsOf: additionalLaunchArguments)
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
	private func assertTextExists(
		_ text: String,
		in app: XCUIApplication,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		XCTAssertTrue(
			app.descendants(matching: .any)[text].exists,
			"SayBar should render \(text) in the current UI surface.",
			file: file,
			line: line,
		)
	}

	@MainActor
	private func assertElementIsHittable(
		_ identifier: String,
		in app: XCUIApplication,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		let element = app.descendants(matching: .any)[identifier]
		XCTAssertTrue(
			element.exists && element.isHittable,
			"SayBar should expose \(identifier) as a reachable menu control.",
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

	@MainActor
	func testMenuQuickActionsRemainTraversableWithoutEmbeddedAutostart() throws {
		let app = makeApp()
		launchAndWait(app)

		XCTContext.runActivity(named: "Open menu extra") { _ in
			openMenuExtra(app)
		}

		XCTContext.runActivity(named: "Verify quick-action controls are reachable") { _ in
			XCTAssertTrue(
				app.descendants(matching: .any)["saybar-menu-window"].waitForExistence(timeout: menuTimeout),
				"SayBar should expose the menu window before checking quick-action reachability.",
			)
			assertElementIsHittable("saybar-resident-model-power", in: app)
			assertElementIsHittable("saybar-playback-or-clipboard-speech", in: app)
			assertElementIsHittable("saybar-open-settings", in: app)
			assertElementExists("saybar-generation-queue", in: app)
			assertElementExists("saybar-generation-queue-summary", in: app)
			assertElementExists("saybar-voice-profile-picker", in: app)
			assertElementExists("saybar-speech-backend-picker", in: app)
		}
	}

	@MainActor
	func testSettingsOpensFromMenuExtraAndExposesStableIdentifiers() throws {
		let app = makeApp()
		launchAndWait(app)

		XCTContext.runActivity(named: "Open Settings from menu extra") { _ in
			openMenuExtra(app)
			app.descendants(matching: .any)["saybar-open-settings"].click()
		}

		XCTContext.runActivity(named: "Verify Settings shell") { _ in
			XCTAssertTrue(
				app.descendants(matching: .any)["saybar-settings-window"].waitForExistence(timeout: menuTimeout),
				"SayBar should open Settings from the menu bar extra and expose the Settings form through a stable accessibility identifier.",
			)
			assertElementExists("saybar-settings-app-section", in: app)
			assertElementExists("saybar-settings-version", in: app)
			assertElementExists("saybar-settings-embedded-autostart", in: app)
			assertElementExists("saybar-settings-menu-bar-extra-toggle", in: app)
			assertElementExists("saybar-settings-runtime-section", in: app)
			assertElementExists("saybar-settings-runtime-status", in: app)
			assertElementExists("saybar-settings-generation-queue", in: app)
			assertElementExists("saybar-settings-playback-queue", in: app)
			assertElementExists("saybar-settings-transports-section", in: app)
			assertElementExists("saybar-settings-recent-errors-section", in: app)
		}
	}

	@MainActor
	func testSettingsCanRenderPopulatedFixtureDiagnostics() throws {
		let app = makeApp(additionalLaunchArguments: ["--saybar-ui-fixture-populated-settings"])
		launchAndWait(app)

		XCTContext.runActivity(named: "Open fixture-backed Settings") { _ in
			openMenuExtra(app)
			app.descendants(matching: .any)["saybar-open-settings"].click()
		}

		XCTContext.runActivity(named: "Verify fixture-backed app and runtime values") { _ in
			XCTAssertTrue(
				app.descendants(matching: .any)["saybar-settings-window"].waitForExistence(timeout: menuTimeout),
				"SayBar should open fixture-backed Settings through the same menu workflow.",
			)
			assertElementExists("saybar-settings-version", in: app)
			assertElementExists("saybar-settings-embedded-autostart", in: app)
			assertElementExists("saybar-settings-menu-bar-extra-toggle", in: app)
			assertElementExists("saybar-settings-runtime-status", in: app)
			assertElementExists("saybar-settings-worker-stage", in: app)
			assertElementExists("saybar-settings-playback-state", in: app)
			assertElementExists("saybar-settings-speech-backend", in: app)
			assertElementExists("saybar-settings-default-voice-profile", in: app)
			assertElementExists("saybar-settings-generation-queue", in: app)
			assertElementExists("saybar-settings-playback-queue", in: app)

			assertTextExists("UI Test Fixture", in: app)
			assertTextExists("Disabled", in: app)
			assertTextExists("degraded", in: app)
			assertTextExists("resident_model_ready", in: app)
			assertTextExists("paused", in: app)
			assertTextExists("marvis", in: app)
			assertTextExists("fixture-femme", in: app)
			assertTextExists("9", in: app)
			assertTextExists("4", in: app)
		}

		XCTContext.runActivity(named: "Verify populated diagnostics") { _ in
			assertElementExists("saybar-settings-transport-row-HTTP", in: app)
			assertElementExists("saybar-settings-recent-error-row-Fixture Runtime", in: app)
			assertTextExists("HTTP", in: app)
			assertTextExists("ready at 127.0.0.1:7339/mcp", in: app)
			assertTextExists("Fixture Runtime", in: app)
			assertTextExists("Fixture warning for Settings diagnostics.", in: app)
		}
	}
}
