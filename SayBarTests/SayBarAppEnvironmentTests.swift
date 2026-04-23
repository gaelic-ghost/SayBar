import XCTest
@testable import SayBar

@MainActor
final class SayBarAppEnvironmentTests: XCTestCase {
	func testAutostartEnabledDefaultsToTrue() {
		XCTAssertTrue(
			SayBarAppEnvironment.autostartEnabled(for: []),
			"SayBar should autostart the embedded runtime unless the UI test launch argument opts out.",
		)
	}

	func testAutostartEnabledRespectsDisableFlag() {
		XCTAssertFalse(
			SayBarAppEnvironment.autostartEnabled(for: ["--saybar-disable-autostart"]),
			"SayBar should disable embedded-runtime autostart when the UI test launch argument requests it.",
		)
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
