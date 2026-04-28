@testable import SayBar
import XCTest

@MainActor
final class SayBarAppLifecycleSupportTests: XCTestCase {
	func testStartupSkipsRuntimeWorkWhenAutostartIsDisabled() async {
		var liftoffCallCount = 0
		var refreshCallCount = 0
		var loggedErrors: [Error] = []

		let result = await SayBarAppLifecycleSupport.startEmbeddedRuntimeIfNeeded(
			autostartEnabled: false,
			liftoff: {
				liftoffCallCount += 1
			},
			refreshVoiceProfiles: {
				refreshCallCount += 1
			},
			logStartupError: { error in
				loggedErrors.append(error)
			}
		)

		XCTAssertEqual(result, .skipped)
		XCTAssertEqual(liftoffCallCount, 0)
		XCTAssertEqual(refreshCallCount, 0)
		XCTAssertTrue(loggedErrors.isEmpty)
	}

	func testStartupLiftsOffThenRefreshesVoiceProfilesWhenAutostartIsEnabled() async {
		var events: [String] = []

		let result = await SayBarAppLifecycleSupport.startEmbeddedRuntimeIfNeeded(
			autostartEnabled: true,
			liftoff: {
				events.append("liftoff")
			},
			refreshVoiceProfiles: {
				events.append("refreshVoiceProfiles")
			},
			logStartupError: { error in
				events.append("log:\(error.localizedDescription)")
			}
		)

		XCTAssertEqual(result, .started)
		XCTAssertEqual(events, ["liftoff", "refreshVoiceProfiles"])
	}

	func testStartupIgnoresInitialVoiceProfileRefreshFailureAfterLiftoff() async {
		var events: [String] = []

		let result = await SayBarAppLifecycleSupport.startEmbeddedRuntimeIfNeeded(
			autostartEnabled: true,
			liftoff: {
				events.append("liftoff")
			},
			refreshVoiceProfiles: {
				events.append("refreshVoiceProfiles")
				throw LifecycleTestError.refreshFailed
			},
			logStartupError: { error in
				events.append("log:\(error.localizedDescription)")
			}
		)

		XCTAssertEqual(result, .started)
		XCTAssertEqual(events, ["liftoff", "refreshVoiceProfiles"])
	}

	func testStartupLogsLiftoffFailureAndSkipsVoiceProfileRefresh() async {
		var events: [String] = []

		let result = await SayBarAppLifecycleSupport.startEmbeddedRuntimeIfNeeded(
			autostartEnabled: true,
			liftoff: {
				events.append("liftoff")
				throw LifecycleTestError.liftoffFailed
			},
			refreshVoiceProfiles: {
				events.append("refreshVoiceProfiles")
			},
			logStartupError: { error in
				events.append("log:\(error.localizedDescription)")
			}
		)

		XCTAssertEqual(result, .failed("liftoff failed"))
		XCTAssertEqual(events, ["liftoff", "log:liftoff failed"])
	}

	func testTerminationRequestMapsAutostartServerAndInFlightState() {
		XCTAssertEqual(
			SayBarAppLifecycleSupport.terminationRequest(
				autostartEnabled: false,
				serverIsAvailable: true,
				isTerminationInFlight: false
			),
			.terminateNow
		)
		XCTAssertEqual(
			SayBarAppLifecycleSupport.terminationRequest(
				autostartEnabled: true,
				serverIsAvailable: false,
				isTerminationInFlight: false
			),
			.terminateNow
		)
		XCTAssertEqual(
			SayBarAppLifecycleSupport.terminationRequest(
				autostartEnabled: true,
				serverIsAvailable: true,
				isTerminationInFlight: true
			),
			.finishExistingTermination
		)
		XCTAssertEqual(
			SayBarAppLifecycleSupport.terminationRequest(
				autostartEnabled: true,
				serverIsAvailable: true,
				isTerminationInFlight: false
			),
			.startNewTermination
		)
	}

	func testFinishTerminationLandsRuntimeBeforeReplying() async {
		var events: [String] = []

		await SayBarAppLifecycleSupport.finishTermination(
			land: {
				events.append("land")
			},
			replyToApplicationShouldTerminate: { shouldTerminate in
				events.append("reply:\(shouldTerminate)")
			},
			logTerminationError: { error in
				events.append("log:\(error.localizedDescription)")
			}
		)

		XCTAssertEqual(events, ["land", "reply:true"])
	}

	func testFinishTerminationLogsLandFailureAndStillReplies() async {
		var events: [String] = []

		await SayBarAppLifecycleSupport.finishTermination(
			land: {
				events.append("land")
				throw LifecycleTestError.landFailed
			},
			replyToApplicationShouldTerminate: { shouldTerminate in
				events.append("reply:\(shouldTerminate)")
			},
			logTerminationError: { error in
				events.append("log:\(error.localizedDescription)")
			}
		)

		XCTAssertEqual(events, ["land", "log:land failed", "reply:true"])
	}
}

private enum LifecycleTestError: LocalizedError {
	case liftoffFailed
	case refreshFailed
	case landFailed

	var errorDescription: String? {
		switch self {
			case .liftoffFailed:
				return "liftoff failed"
			case .refreshFailed:
				return "refresh failed"
			case .landFailed:
				return "land failed"
		}
	}
}
