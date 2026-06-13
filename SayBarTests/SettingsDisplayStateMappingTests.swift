@testable import SayBar
import SpeakSwiftlyServer
import XCTest

@MainActor
final class SettingsDisplayStateMappingTests: XCTestCase {
    func testConfigurationDiagnosticsIncludeRuntimeDuckingFields() throws {
        let configuration = try decoded(
            RuntimeConfigurationSnapshot.self,
            from: """
            {
              "active_runtime_speech_backend": "qwen3_smol_4bit",
              "next_runtime_speech_backend": "qwen3_smol",
              "active_duck_media_volume": "medium",
              "next_duck_media_volume": "soft",
              "active_default_voice_profile_name": "default-femme",
              "next_default_voice_profile_name": "default-masc",
              "environment_speech_backend_override": "qwen3_smol_4bit",
              "persisted_speech_backend": "qwen3_smol",
              "persisted_duck_media_volume": "soft",
              "persisted_default_voice_profile_name": "default-femme",
              "profile_root_path": "/tmp/saybar/profiles",
              "persisted_configuration_path": "/tmp/saybar/server.yaml",
              "persisted_configuration_exists": true,
              "persisted_configuration_state": "loaded",
              "persisted_configuration_error": null,
              "persisted_configuration_applies_on_restart": true,
              "active_runtime_matches_next_runtime": false,
              "persisted_configuration_will_affect_next_runtime_start": true
            }
            """
        )

        let rows = SettingsDisplayState.configurationDiagnostics(from: configuration)

        XCTAssertEqual(rows.first { $0.id == "active-duck-media-volume" }?.value, "medium")
        XCTAssertEqual(rows.first { $0.id == "next-duck-media-volume" }?.value, "soft")
        XCTAssertEqual(rows.first { $0.id == "persisted-duck-media-volume" }?.value, "soft")
        XCTAssertEqual(rows.first { $0.id == "configuration-exists" }?.value, "Yes")
    }

    func testTransportRowIncludesV11TransportMetadata() throws {
        let transport = try decoded(
            TransportStatusSnapshot.self,
            from: """
            {
              "name": "HTTP",
              "enabled": true,
              "state": "listening",
              "host": "127.0.0.1",
              "port": 7339,
              "path": "/mcp",
              "advertised_address": "http://127.0.0.1:7339",
              "active_stream_count": 2
            }
            """
        )

        let row = SettingsDisplayState.transportRow(index: 0, transport: transport)

        XCTAssertEqual(row.summary, "listening at 127.0.0.1:7339/mcp")
        XCTAssertEqual(row.enabled, "Yes")
        XCTAssertEqual(row.advertisedAddress, "http://127.0.0.1:7339")
        XCTAssertEqual(row.activeStreamCount, "2")
    }

    func testNetworkAudioReceiverDiagnosticsIncludeSelectionState() throws {
        let selection = try decoded(
            NetworkAudioReceiverSelectionSnapshot.self,
            from: """
            {
              "selected_destination_id": "fixture-speaker",
              "available_destination_count": 1,
              "shared_token_configured": true,
              "selected_destination_endpoint_ready": true,
              "lan_output_ready": false,
              "lan_output_blocked_reasons": ["network_audio_receiver_shared_token_missing"]
            }
            """
        )

        let rows = SettingsDisplayState.networkAudioReceiverDiagnostics(from: selection)

        XCTAssertEqual(rows.first { $0.id == "network-audio-selected-destination" }?.value, "fixture-speaker")
        XCTAssertEqual(rows.first { $0.id == "network-audio-available-destinations" }?.value, "1")
        XCTAssertEqual(rows.first { $0.id == "network-audio-shared-token" }?.value, "Yes")
        XCTAssertEqual(rows.first { $0.id == "network-audio-lan-output-ready" }?.value, "No")
        XCTAssertEqual(
            rows.first { $0.id == "network-audio-blocked-reasons" }?.value,
            "network_audio_receiver_shared_token_missing"
        )
    }

    func testNetworkAudioDestinationRowSummarizesEndpointAndCapabilities() throws {
        let destination = try decoded(
            NetworkAudioDestinationSnapshot.self,
            from: """
            {
              "id": "fixture-speaker",
              "name": "Fixture Speaker",
              "endpoint": {
                "kind": "host_port",
                "host": "10.0.0.42",
                "port": 9010
              },
              "capabilities": {
                "protocol_version": 1,
                "sample_formats": ["pcm_f32"],
                "sample_rates": [24000, 48000],
                "channel_counts": [1, 2]
              },
              "last_seen": "2026-06-06T12:00:00Z"
            }
            """
        )

        let row = SettingsDisplayState.networkAudioDestinationRow(index: 0, destination: destination)

        XCTAssertEqual(row.id, "fixture-speaker")
        XCTAssertEqual(row.name, "Fixture Speaker")
        XCTAssertEqual(row.endpoint, "10.0.0.42:9010")
        XCTAssertEqual(row.capabilities, "v1; pcm_f32; 24000, 48000 Hz; 1, 2 channel(s)")
        XCTAssertEqual(row.lastSeen, "2026-06-06T12:00:00Z")
    }

    func testRecentErrorRowIncludesCodeAndTimestamp() throws {
        let error = try decoded(
            RecentErrorSnapshot.self,
            from: """
            {
              "occurred_at": "2026-06-06T12:01:00Z",
              "source": "Fixture Runtime",
              "code": "fixture_warning",
              "message": "Fixture warning for Settings diagnostics."
            }
            """
        )

        let row = SettingsDisplayState.recentErrorRow(index: 0, error: error)

        XCTAssertEqual(row.source, "Fixture Runtime")
        XCTAssertEqual(row.code, "fixture_warning")
        XCTAssertEqual(row.occurredAt, "2026-06-06T12:01:00Z")
        XCTAssertEqual(row.message, "Fixture warning for Settings diagnostics.")
    }

    private func decoded<T: Decodable>(
        _ type: T.Type,
        from json: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> T {
        let data = try XCTUnwrap(json.data(using: .utf8), file: file, line: line)
        return try JSONDecoder().decode(type, from: data)
    }
}
