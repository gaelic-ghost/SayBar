import XCTest
@testable import SayBar

@MainActor
final class SayBarAppEnvironmentTests: XCTestCase {
	func testAutostartEnabledDefaultsToTrue() {
		XCTAssertFalse(
			SayBarAppEnvironment.autostartDisabledForLaunch(for: []),
			"SayBar should leave embedded-runtime autostart available unless the UI test launch argument opts out.",
		)
	}

	func testAutostartEnabledRespectsDisableFlag() {
		XCTAssertTrue(
			SayBarAppEnvironment.autostartDisabledForLaunch(for: ["--saybar-disable-autostart"]),
			"SayBar should suppress embedded-runtime autostart for this launch when the UI test launch argument requests it.",
		)
	}

	func testPersistedEmbeddedRuntimeAutostartDefaultsToTrue() {
		let suiteName = "SayBarAppEnvironmentTests-\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		defer { defaults.removePersistentDomain(forName: suiteName) }

		XCTAssertTrue(
			SayBarAppEnvironment.persistedEmbeddedRuntimeAutostartEnabled(
				defaults: defaults,
				key: "embeddedRuntimeAutostartEnabled"
			),
			"SayBar should default embedded-runtime autostart on for normal app launches.",
		)
	}

	func testPersistedEmbeddedRuntimeAutostartReadsStoredBool() {
		let suiteName = "SayBarAppEnvironmentTests-\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		defer { defaults.removePersistentDomain(forName: suiteName) }
		defaults.set(false, forKey: "embeddedRuntimeAutostartEnabled")

		XCTAssertFalse(
			SayBarAppEnvironment.persistedEmbeddedRuntimeAutostartEnabled(
				defaults: defaults,
				key: "embeddedRuntimeAutostartEnabled"
			),
			"SayBar should honor the persisted Settings toggle for embedded-runtime autostart.",
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
}
