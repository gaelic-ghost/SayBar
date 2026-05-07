import XCTest
@testable import SayBar

@MainActor
final class SayBarAppEnvironmentTests: XCTestCase {
	func testEmbeddedRuntimeLaunchDefaultsToTrue() {
		XCTAssertTrue(
			SayBarAppEnvironment.launchesEmbeddedRuntime(for: []),
			"SayBar should start the embedded runtime for normal launches.",
		)
	}

	func testEmbeddedRuntimeLaunchRespectsSkipFlag() {
		XCTAssertFalse(
			SayBarAppEnvironment.launchesEmbeddedRuntime(for: ["--saybar-skip-embedded-runtime-startup"]),
			"SayBar should skip embedded runtime startup only when this launch explicitly requests lightweight test/debug mode.",
		)
	}

	func testSettingsDisplayStateOverrideDefaultsToNil() {
		XCTAssertNil(
			SayBarAppEnvironment.settingsDisplayStateOverride(for: []),
			"SayBar should use live embedded runtime state for Settings unless a UI-test fixture is explicitly requested.",
		)
	}

	func testSettingsDisplayStateOverrideUsesPopulatedFixtureFlag() throws {
		let fixture = try XCTUnwrap(
			SayBarAppEnvironment.settingsDisplayStateOverride(for: ["--saybar-ui-fixture-populated-settings"]),
			"SayBar should expose a deterministic populated Settings fixture for UI tests.",
		)

		XCTAssertEqual(fixture.appInfo.buildVersion, "UI Test Fixture")
		XCTAssertEqual(fixture.runtimeOverview.status, "degraded")
		XCTAssertEqual(fixture.runtimeOverview.generationQueueCount, "9")
		XCTAssertEqual(fixture.runtimeOverview.playbackQueueCount, "4")
		XCTAssertEqual(fixture.transports.first?.name, "HTTP")
		XCTAssertEqual(fixture.recentErrors.first?.source, "Fixture Runtime")
	}

	func testRuntimeProfileRootURLUsesApplicationSupportDirectory() throws {
		let fileManager = FileManager.default
		let applicationSupportURL = try XCTUnwrap(
			fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
			"The test environment should provide a user Application Support directory.",
		)

		let runtimeURL = try XCTUnwrap(
			SayBarAppEnvironment.runtimeProfileRootURL(fileManager: fileManager),
			"SayBar should derive a runtime profile directory underneath Application Support.",
		)

		XCTAssertEqual(
			runtimeURL,
			applicationSupportURL.appendingPathComponent("SayBar/SpeakSwiftlyRuntime", isDirectory: true),
			"SayBar should keep embedded runtime profiles in a stable app-owned Application Support subdirectory.",
		)
	}

	func testRuntimeConfigurationURLUsesApplicationSupportDirectory() throws {
		let fileManager = FileManager.default
		let applicationSupportURL = try XCTUnwrap(
			fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
			"The test environment should provide a user Application Support directory.",
		)

		let configurationURL = try XCTUnwrap(
			SayBarAppEnvironment.runtimeConfigurationURL(fileManager: fileManager),
			"SayBar should derive an embedded server configuration file underneath Application Support.",
		)

		XCTAssertEqual(
			configurationURL,
			applicationSupportURL
				.appendingPathComponent("SayBar", isDirectory: true)
				.appendingPathComponent("server.yaml", isDirectory: false),
			"SayBar should keep embedded server configuration in the same app-owned Application Support root as runtime profiles.",
		)
	}
}
