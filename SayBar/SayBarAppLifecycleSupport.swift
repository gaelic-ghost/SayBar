//
//  SayBarAppLifecycleSupport.swift
//  SayBar
//
//  Created by Gale Williams on 3/30/26.
//

import Foundation

enum SayBarAppLifecycleSupport {
	enum StartupResult: Equatable {
		case skipped
		case started
		case failed(String)
	}

	enum TerminationRequest: Equatable {
		case terminateNow
		case finishExistingTermination
		case startNewTermination
	}

	@MainActor
	static func startEmbeddedRuntimeIfRequested(
		launchesEmbeddedRuntime: Bool,
		liftoff: () async throws -> Void,
		refreshVoiceProfiles: () async throws -> Void,
		logStartupError: (Error) -> Void
	) async -> StartupResult {
		guard launchesEmbeddedRuntime else {
			return .skipped
		}

		do {
			try await liftoff()
			_ = try? await refreshVoiceProfiles()
			return .started
		} catch {
			logStartupError(error)
			return .failed(error.localizedDescription)
		}
	}

	nonisolated static func terminationRequest(
		launchesEmbeddedRuntime: Bool,
		serverIsAvailable: Bool,
		isTerminationInFlight: Bool
	) -> TerminationRequest {
		guard launchesEmbeddedRuntime, serverIsAvailable else {
			return .terminateNow
		}

		return isTerminationInFlight ? .finishExistingTermination : .startNewTermination
	}

	@MainActor
	static func finishTermination(
		land: () async throws -> Void,
		replyToApplicationShouldTerminate: (Bool) -> Void,
		logTerminationError: (Error) -> Void
	) async {
		defer {
			replyToApplicationShouldTerminate(true)
		}

		do {
			try await land()
		} catch {
			logTerminationError(error)
		}
	}
}
