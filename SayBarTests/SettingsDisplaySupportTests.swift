@testable import SayBar
import XCTest

final class SettingsDisplaySupportTests: XCTestCase {
    func testEnabledStatusMapsBooleanState() {
        XCTAssertEqual(SettingsDisplaySupport.enabledStatus(true), "Enabled")
        XCTAssertEqual(SettingsDisplaySupport.enabledStatus(false), "Disabled")
    }

    func testDefaultVoiceProfileNameFallsBackToNone() {
        XCTAssertEqual(SettingsDisplaySupport.defaultVoiceProfileName("default-femme"), "default-femme")
        XCTAssertEqual(SettingsDisplaySupport.defaultVoiceProfileName(nil), "None")
    }

    func testQueueCountCombinesActiveAndQueuedCounts() {
        XCTAssertEqual(SettingsDisplaySupport.queueCount(activeCount: 2, queuedCount: 3), "5")
        XCTAssertEqual(SettingsDisplaySupport.queueCount(activeCount: 0, queuedCount: 0), "0")
    }

    func testQueueCountDropsNegativeCounts() {
        XCTAssertEqual(SettingsDisplaySupport.queueCount(activeCount: -2, queuedCount: 3), "3")
        XCTAssertEqual(SettingsDisplaySupport.queueCount(activeCount: 2, queuedCount: -3), "2")
        XCTAssertEqual(SettingsDisplaySupport.queueCount(activeCount: -2, queuedCount: -3), "0")
    }

    func testTransportSummaryUsesRootPathWhenPathIsMissing() {
        XCTAssertEqual(
            SettingsDisplaySupport.transportSummary(
                state: "ready",
                host: nil,
                port: nil,
                path: nil
            ),
            "ready at /"
        )
    }

    func testTransportSummaryCombinesHostPortAndPath() {
        XCTAssertEqual(
            SettingsDisplaySupport.transportSummary(
                state: "ready",
                host: "127.0.0.1",
                port: 7339,
                path: "/mcp"
            ),
            "ready at 127.0.0.1:7339/mcp"
        )
    }

    func testTransportSummaryUsesHostWithoutPort() {
        XCTAssertEqual(
            SettingsDisplaySupport.transportSummary(
                state: "degraded",
                host: "localhost",
                port: nil,
                path: "/"
            ),
            "degraded at localhost/"
        )
    }
}
