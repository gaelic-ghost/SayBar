//
//  SayBarUITestsLaunchTests.swift
//  SayBarUITests
//
//  Created by Gale Williams on 3/30/26.
//

import XCTest

final class SayBarUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
		throw XCTSkip("SayBar uses focused launch coverage in SayBarUITests instead of the stock screenshot-oriented launch template test.")
    }
}
