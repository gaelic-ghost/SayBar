@testable import SayBar
import XCTest

final class SettingsDisplaySupportTests: XCTestCase {
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
