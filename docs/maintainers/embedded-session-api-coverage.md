# Embedded Session API Coverage

## Source Of Truth

This matrix audits SayBar against the embedded app-facing API exposed by `SpeakSwiftlyServer` `12.0.0`, resolved in `SayBar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

The current SayBar product baseline is still embedded-runtime-first. That means `EmbeddedServer` is in scope for active app behavior, while standalone LaunchAgent install helpers remain future-scope until SayBar intentionally grows an app-managed standalone-server mode.

## Coverage Matrix

| API surface | Available from | SayBar coverage | Current SayBar use |
| --- | --- | --- | --- |
| `EmbeddedServer` | `SpeakSwiftlyServer` | Implemented | One long-lived observable app model owned by `SayBarApp` and passed directly into menu bar and Settings scenes. |
| `EmbeddedServer.Options.port` | `EmbeddedServer.Options` | Implemented | Pins the embedded HTTP transport to port `7339`. |
| `EmbeddedServer.Options.runtimeProfileRootURL` | `EmbeddedServer.Options` | Implemented | Points the embedded runtime at SayBar-owned Application Support profile storage. |
| `EmbeddedServer.Options.configurationURL` | `EmbeddedServer.Options` | Implemented | Points the embedded runtime at SayBar-owned Application Support server configuration. |
| `EmbeddedServer.init(options:)` | `EmbeddedServer` | Implemented | Creates the app-owned embedded runtime model during app initialization. |
| `liftoff(environment:)` | `EmbeddedServer` | Implemented | Starts the embedded runtime on launch unless `--saybar-skip-embedded-runtime-startup` is present. |
| `land()` | `EmbeddedServer` | Implemented | Requests graceful embedded runtime shutdown before macOS app termination completes. |
| `overview` | `EmbeddedServer` | Implemented | Drives menu status text, startup-error display, worker readiness, model-loaded state, and default voice fallback. |
| `overview.service` | `HostOverviewSnapshot` | Implemented | Displayed in Settings runtime details. |
| `overview.environment` | `HostOverviewSnapshot` | Implemented | Displayed in Settings runtime details. |
| `overview.defaultVoiceProfileName` | `HostOverviewSnapshot` | Implemented | Selects the active voice profile in the quick-config menu picker and shows the default profile in Settings. |
| `overview.serverMode` | `HostOverviewSnapshot` | Implemented | Drives high-level ready, degraded, broken, or starting menu status and Settings status. |
| `overview.workerMode` | `HostOverviewSnapshot` | Implemented | Displayed in Settings runtime details. |
| `overview.workerStage` | `HostOverviewSnapshot` | Implemented | Drives menu status detail and resident-model power-button state. |
| `overview.workerReady` | `HostOverviewSnapshot` | Implemented | Helps decide when the menu can report that the embedded runtime is ready. |
| `overview.startupError` | `HostOverviewSnapshot` | Implemented | Displayed as the highest-priority startup problem in the menu status text. |
| `overview.profileCacheState` | `HostOverviewSnapshot` | Implemented | Displayed in Settings runtime details. |
| `overview.profileCacheWarning` | `HostOverviewSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `overview.profileCount` | `HostOverviewSnapshot` | Implemented | Displayed in Settings runtime details; the menu picker still reads `voiceProfiles` directly. |
| `overview.lastProfileRefreshAt` | `HostOverviewSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `generationQueue` | `EmbeddedServer` | Implemented, partial | The menu queues surface shows separate active and queued generation counts as a 24-slot indicator plus request rows; Settings shows summary and diagnostics counts. |
| `generationQueue.queueType` | `QueueStatusSnapshot` | Not surfaced | Available for diagnostics, but the menu already labels this queue as generation work. |
| `generationQueue.activeCount` | `QueueStatusSnapshot` | Implemented | Contributes to the menu queues surface and Settings generation queue count. |
| `generationQueue.queuedCount` | `QueueStatusSnapshot` | Implemented | Contributes to the menu queues surface and Settings generation queue count. |
| `generationQueue.activeRequest` | `QueueStatusSnapshot` | Implemented indirectly | Settings lists active generation requests through `activeRequests`. |
| `generationQueue.activeRequests` | `QueueStatusSnapshot` | Implemented | Settings queue diagnostics list active generation request id, operation, and profile. |
| `generationQueue.queuedRequests` | `QueueStatusSnapshot` | Implemented | Settings queue diagnostics list queued generation request id, operation, profile, and queue position. |
| `playbackQueue` | `EmbeddedServer` | Implemented, partial | The menu queues surface and Settings diagnostics show active plus queued playback count. |
| `playbackQueue.queueType` | `QueueStatusSnapshot` | Not surfaced | Available for diagnostics, but Settings already labels this count as playback queue work. |
| `playbackQueue.activeCount` | `QueueStatusSnapshot` | Implemented | Contributes to the Settings playback queue count. |
| `playbackQueue.queuedCount` | `QueueStatusSnapshot` | Implemented | Contributes to the Settings playback queue count. |
| `playbackQueue.activeRequest` | `QueueStatusSnapshot` | Not surfaced | Available for playback request diagnostics, but SayBar currently uses `playback.activeRequest` for active playback text. |
| `playbackQueue.activeRequests` | `QueueStatusSnapshot` | Implemented | Settings queue diagnostics list active playback request id, operation, and profile. |
| `playbackQueue.queuedRequests` | `QueueStatusSnapshot` | Implemented | Settings queue diagnostics list queued playback request id, operation, profile, and queue position. |
| `playback` | `EmbeddedServer` | Implemented, partial | Drives menu playback headline, detail text, and pause/resume/clipboard button behavior. |
| `playback.sequence` | `PlaybackStatusSnapshot` | Implemented | Displayed in Settings playback details with a `None` fallback. |
| `playback.updatedAt` | `PlaybackStatusSnapshot` | Implemented | Displayed in Settings playback details with a `None` fallback. |
| `playback.state` | `PlaybackStatusSnapshot` | Implemented | Switches menu wording and playback button icon between pause, resume, and clipboard speech. |
| `playback.activeRequest` | `PlaybackStatusSnapshot` | Implemented, partial | Menu detail displays the active playback request identifier when playback is active. |
| `playback.isStableForConcurrentGeneration` | `PlaybackStatusSnapshot` | Implemented | Displayed in Settings playback details. |
| `playback.isRebuffering` | `PlaybackStatusSnapshot` | Implemented | Displayed in Settings playback details. |
| `playback.stableBufferedAudioMS` | `PlaybackStatusSnapshot` | Implemented | Displayed in Settings playback details with a `None` fallback. |
| `playback.stableBufferTargetMS` | `PlaybackStatusSnapshot` | Implemented | Displayed in Settings playback details with a `None` fallback. |
| `playback.latestEvent` | `PlaybackStatusSnapshot` | Implemented, partial | Settings displays the latest event label and current device when present. |
| `playback.latestEvent.sequence` | `PlaybackEventSnapshot` | Not surfaced | Available for playback event diagnostics, but SayBar does not show event sequence identifiers in current Settings diagnostics. |
| `playback.latestEvent.publishedAt` | `PlaybackEventSnapshot` | Not surfaced | Available for playback event diagnostics, but SayBar does not show event publish timestamps in current Settings diagnostics. |
| `playback.latestEvent.event` | `PlaybackEventSnapshot` | Implemented | Displayed in Settings playback details with a `None` fallback. |
| `playback.latestEvent.state` | `PlaybackEventSnapshot` | Not surfaced | Available for playback event diagnostics, but SayBar uses `playback.state` for current UI state. |
| `playback.latestEvent.requestID` | `PlaybackEventSnapshot` | Not surfaced | Available for playback event diagnostics, but SayBar does not show event request identifiers in current Settings diagnostics. |
| `playback.latestEvent.activeRequest` | `PlaybackEventSnapshot` | Not surfaced | Available for playback event diagnostics, but SayBar uses `playback.activeRequest` for current active playback text. |
| `playback.latestEvent.queuedRequests` | `PlaybackEventSnapshot` | Not surfaced | Available for playback queue diagnostics, but SayBar does not list queued playback requests in current Settings diagnostics. |
| `playback.latestEvent.bufferedAudioMS` | `PlaybackEventSnapshot` | Not surfaced | Available for playback buffering diagnostics, but SayBar does not show event buffer duration in current Settings diagnostics. |
| `playback.latestEvent.queuedAudioMS` | `PlaybackEventSnapshot` | Not surfaced | Available for playback queue diagnostics, but SayBar does not show queued audio duration in current Settings diagnostics. |
| `playback.latestEvent.bufferTargetMS` | `PlaybackEventSnapshot` | Not surfaced | Available for playback buffering diagnostics, but SayBar does not show target buffer duration in current Settings diagnostics. |
| `playback.latestEvent.previousDevice` | `PlaybackEventSnapshot` | Not surfaced | Available for output-device diagnostics, but SayBar does not show playback device changes in current Settings diagnostics. |
| `playback.latestEvent.currentDevice` | `PlaybackEventSnapshot` | Implemented | Displayed in Settings playback details with a `None` fallback. |
| `playback.latestEvent.isInterrupted` | `PlaybackEventSnapshot` | Not surfaced | Available for playback interruption diagnostics, but SayBar does not show interruption state in current Settings diagnostics. |
| `playback.latestEvent.shouldResume` | `PlaybackEventSnapshot` | Not surfaced | Available for playback interruption diagnostics, but SayBar does not show resume recommendations in current Settings diagnostics. |
| `runtimeRefresh` | `EmbeddedServer` | Implemented | Settings runtime details display refresh sequence, source, timing markers, and completion. |
| `runtimeRefresh.sequenceID` | `RuntimeRefreshSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeRefresh.source` | `RuntimeRefreshSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeRefresh.startedAt` | `RuntimeRefreshSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeRefresh.generationQueueRefreshedAt` | `RuntimeRefreshSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeRefresh.playbackQueueRefreshedAt` | `RuntimeRefreshSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeRefresh.playbackStateRefreshedAt` | `RuntimeRefreshSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeRefresh.completedAt` | `RuntimeRefreshSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeBackendTransition` | `EmbeddedServer` | Implemented | Settings runtime details display backend-switch state, requested backend, request id, operation, waiting reason, and timestamps. |
| `runtimeBackendTransition.state` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details. |
| `runtimeBackendTransition.activeSpeechBackend` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details; the menu picker still reads `runtimeConfiguration.activeRuntimeSpeechBackend`. |
| `runtimeBackendTransition.requestedSpeechBackend` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeBackendTransition.requestID` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeBackendTransition.operation` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeBackendTransition.waitingReason` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeBackendTransition.submittedAt` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `runtimeBackendTransition.startedAt` | `RuntimeBackendTransitionSnapshot` | Implemented | Displayed in Settings runtime details with a `None` fallback. |
| `currentGenerationJobs` | `EmbeddedServer` | Implemented, partial | Settings lists active generation jobs with operation, profile, latest stage, and elapsed generation time. |
| `currentGenerationJobs[].jobID` | `CurrentGenerationJobSnapshot` | Implemented | Used as the stable Settings generation-job row identifier. |
| `currentGenerationJobs[].op` | `CurrentGenerationJobSnapshot` | Implemented | Displayed in Settings generation-job rows. |
| `currentGenerationJobs[].profileName` | `CurrentGenerationJobSnapshot` | Implemented | Displayed in Settings generation-job rows with a `None` fallback. |
| `currentGenerationJobs[].submittedAt` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for job diagnostics, but SayBar does not show submission time in current Settings diagnostics. |
| `currentGenerationJobs[].startedAt` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for job diagnostics, but SayBar does not show start time in current Settings diagnostics. |
| `currentGenerationJobs[].latestStage` | `CurrentGenerationJobSnapshot` | Implemented | Displayed in Settings generation-job rows with a `None` fallback. |
| `currentGenerationJobs[].elapsedGenerationSeconds` | `CurrentGenerationJobSnapshot` | Implemented | Displayed in Settings generation-job rows with a `None` fallback. |
| `runtimeConfiguration` | `EmbeddedServer` | Implemented | Settings displays active, next-start, persisted, ducking, path, and restart-impact configuration details; the quick-config menu backend picker reads the active backend. |
| `runtimeConfiguration.activeRuntimeSpeechBackend` | `RuntimeConfigurationSnapshot` | Implemented | Drives the quick-config backend picker selection and Settings speech backend value. |
| `runtimeConfiguration.nextRuntimeSpeechBackend` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.activeDuckMediaVolume` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.nextDuckMediaVolume` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.activeDefaultVoiceProfileName` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details with a `None` fallback; the primary runtime section still uses `overview.defaultVoiceProfileName`. |
| `runtimeConfiguration.nextDefaultVoiceProfileName` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details with a `None` fallback. |
| `runtimeConfiguration.environmentSpeechBackendOverride` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details with a `None` fallback. |
| `runtimeConfiguration.persistedSpeechBackend` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details with a `None` fallback. |
| `runtimeConfiguration.persistedDuckMediaVolume` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details with a `None` fallback. |
| `runtimeConfiguration.persistedDefaultVoiceProfileName` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details with a `None` fallback. |
| `runtimeConfiguration.profileRootPath` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.persistedConfigurationPath` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.persistedConfigurationExists` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.persistedConfigurationState` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.persistedConfigurationError` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details with a `None` fallback. |
| `runtimeConfiguration.persistedConfigurationAppliesOnRestart` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.activeRuntimeMatchesNextRuntime` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `runtimeConfiguration.persistedConfigurationWillAffectNextRuntimeStart` | `RuntimeConfigurationSnapshot` | Implemented | Displayed in Settings configuration details. |
| `voiceProfiles` | `EmbeddedServer` | Implemented | Populates the quick-config menu voice-profile picker and disables the picker when no profiles are cached. |
| `voiceProfiles[].profileName` | `ProfileSnapshot` | Implemented | Displayed as each picker option and used as the picker tag. |
| `voiceProfiles[].vibe` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show profile vibe in current Settings diagnostics. |
| `voiceProfiles[].createdAt` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show profile creation time in current Settings diagnostics. |
| `voiceProfiles[].voiceDescription` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show voice descriptions in current Settings diagnostics. |
| `voiceProfiles[].sourceText` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show source text in current Settings diagnostics. |
| `transports` | `EmbeddedServer` | Implemented | Settings lists transport name, state/address/path summary, enabled state, advertised address, and active stream count. |
| `transports[].name` | `TransportStatusSnapshot` | Implemented | Displayed as the transport row headline in Settings. |
| `transports[].enabled` | `TransportStatusSnapshot` | Implemented | Displayed in each Settings transport row. |
| `transports[].state` | `TransportStatusSnapshot` | Implemented | Displayed in each transport summary. |
| `transports[].host` | `TransportStatusSnapshot` | Implemented | Used to compose each transport address summary. |
| `transports[].port` | `TransportStatusSnapshot` | Implemented | Used to compose each transport address summary. |
| `transports[].path` | `TransportStatusSnapshot` | Implemented | Used to compose each transport path summary. |
| `transports[].advertisedAddress` | `TransportStatusSnapshot` | Implemented | Displayed in each Settings transport row with a `None` fallback. |
| `transports[].activeStreamCount` | `TransportStatusSnapshot` | Implemented | Displayed in each Settings transport row with a `None` fallback. |
| `networkAudioDestinations` | `EmbeddedServer` | Implemented | Settings lists visible LAN audio receivers with endpoint, capabilities, and last-seen time. |
| `networkAudioDestinations[].id` | `NetworkAudioDestinationSnapshot` | Implemented | Used as the stable Settings destination-row identifier. |
| `networkAudioDestinations[].name` | `NetworkAudioDestinationSnapshot` | Implemented | Displayed as the Settings network-audio destination row headline. |
| `networkAudioDestinations[].endpoint` | `NetworkAudioDestinationSnapshot` | Implemented | Displayed as a host:port or Bonjour service label in Settings. |
| `networkAudioDestinations[].capabilities` | `NetworkAudioDestinationSnapshot` | Implemented | Displayed as protocol, sample format, sample rate, and channel-count details in Settings. |
| `networkAudioDestinations[].lastSeen` | `NetworkAudioDestinationSnapshot` | Implemented | Displayed in each Settings network-audio destination row. |
| `networkAudioReceiverSelection` | `EmbeddedServer` | Implemented | Settings displays selected destination, destination count, token state, endpoint readiness, LAN output readiness, and blocked reasons. |
| `remoteGeneration` | `HostStateSnapshot` | Not exposed by `EmbeddedServer` | `SpeakSwiftlyServer` 12.0.0 includes this in `HostStateSnapshot`, but the public `EmbeddedServer` observable does not publish or apply it, so SayBar does not add a side channel in this direct-ownership pass. |
| `recentErrors` | `EmbeddedServer` | Implemented | Menu uses the newest error message as high-priority status detail; Settings lists retained errors with source, code, timestamp, and message. |
| `recentErrors[].occurredAt` | `RecentErrorSnapshot` | Implemented | Displayed in each Settings error row. |
| `recentErrors[].source` | `RecentErrorSnapshot` | Implemented | Displayed as the Settings error row headline. |
| `recentErrors[].code` | `RecentErrorSnapshot` | Implemented | Displayed in each Settings error row. |
| `recentErrors[].message` | `RecentErrorSnapshot` | Implemented | Displayed in menu status detail and Settings error row detail. |
| `listVoiceProfiles()` | `EmbeddedServer` | Not used | Redundant for current UI because SwiftUI reads the observable `voiceProfiles` property directly. |
| `refreshVoiceProfiles()` | `EmbeddedServer` | Implemented | Called after startup and when the menu opens with an empty profile cache. |
| `queueLiveSpeech(text:profileName:textProfileID:requestContext:qwenPreModelTextChunking:)` | `EmbeddedServer` | Implemented, basic | Menu playback button queues trimmed clipboard text with SayBar clipboard request context marked as live speech while leaving profile, text profile, and chunking options at their defaults. |
| `setDefaultVoiceProfileName(_:)` | `EmbeddedServer` | Implemented | The quick-config voice-profile picker updates the embedded host's default voice profile. |
| `clearDefaultVoiceProfileName()` | `EmbeddedServer` | Not used | Available for a future reset/default-profile UI action. |
| `switchSpeechBackend(to:)` | `EmbeddedServer` | Implemented | The quick-config speech-backend picker switches the running runtime backend. |
| `reloadModels()` | `EmbeddedServer` | Implemented | Resident-model power control reloads runtime models when models are unloaded. |
| `unloadModels()` | `EmbeddedServer` | Implemented | Resident-model power control unloads runtime models when models are loaded. |
| `pausePlayback()` | `EmbeddedServer` | Implemented | Playback control pauses active playback. |
| `resumePlayback()` | `EmbeddedServer` | Implemented | Playback control resumes paused playback. |
| `clearPlaybackQueue()` | `EmbeddedServer` | Implemented | Menu and Settings playback queue clear buttons use a native destructive confirmation before calling the direct embedded action. |
| `cancelPlaybackRequest(_:)` | `EmbeddedServer` | Implemented | Menu and Settings playback request controls cancel visible active or selected playback requests through the direct embedded action. |
| `ActiveRequestSnapshot.id` | Queue and playback snapshots | Implemented | Displayed in menu playback detail when active and in Settings queue diagnostics for active queue rows. |
| `ActiveRequestSnapshot.op` | Queue and playback snapshots | Implemented | Displayed in Settings active request rows. |
| `ActiveRequestSnapshot.profileName` | Queue and playback snapshots | Implemented | Displayed in Settings active request rows with a `None` fallback. |
| `QueuedRequestSnapshot.id` | Queue snapshots | Implemented | Displayed in Settings queued request rows. |
| `QueuedRequestSnapshot.op` | Queue snapshots | Implemented | Displayed in Settings queued request rows. |
| `QueuedRequestSnapshot.profileName` | Queue snapshots | Implemented | Displayed in Settings queued request rows with a `None` fallback. |
| `QueuedRequestSnapshot.queuePosition` | Queue snapshots | Implemented | Displayed in Settings queued request rows. |
| `HostStateSnapshot` | Control action returns | Consumed indirectly | Backend switch and model load/unload actions apply refreshed host state inside `EmbeddedServer`; SayBar reads the updated observable properties afterward. |
| `HostStateSnapshot.overview` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer` after backend/model actions; SayBar observes `server.overview`. |
| `HostStateSnapshot.runtimeRefresh` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings displays refresh diagnostics. |
| `HostStateSnapshot.generationQueue` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; SayBar observes queue counts. |
| `HostStateSnapshot.playbackQueue` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings observes playback queue count. |
| `HostStateSnapshot.playback` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; SayBar observes playback state. |
| `HostStateSnapshot.runtimeBackendTransition` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings displays backend transition diagnostics. |
| `HostStateSnapshot.currentGenerationJobs` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings displays active generation job diagnostics. |
| `HostStateSnapshot.runtimeConfiguration` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings displays active, next-start, persisted, and restart-impact configuration diagnostics. |
| `HostStateSnapshot.remoteGeneration` | `HostStateSnapshot` | Not consumed | The v12 `HostStateSnapshot` has this field, but `EmbeddedServer.applyHostStateSnapshot(_:)` does not publish it on `EmbeddedServer`; SayBar intentionally leaves it unsurfaced until the embedded library exposes it directly. |
| `HostStateSnapshot.transports` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings displays transport diagnostics. |
| `HostStateSnapshot.networkAudioDestinations` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings displays visible LAN audio receiver diagnostics. |
| `HostStateSnapshot.networkAudioReceiverSelection` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings displays LAN audio receiver selection diagnostics. |
| `HostStateSnapshot.recentErrors` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; menu and Settings display retained error messages. |

## Coverage Summary

SayBar covers the core embedded-session baseline: app-owned lifecycle, observable status, queue counts and request rows, playback state and buffering diagnostics, runtime refresh and backend-transition diagnostics, runtime configuration including ducking fields, transport diagnostics, network audio receiver diagnostics, recent errors, voice profile refresh and selection, speech backend switching, resident model load/unload, playback pause/resume, playback queue clear/cancel controls, and clipboard-to-speech submission.

The main embedded-session gaps are operator controls and diagnostics that are still either intentionally out of scope or not exposed through the direct `EmbeddedServer` observable: generation queue clear/cancel actions, full playback event details, generation-job submitted/start timestamps, profile metadata beyond profile names, and remote-generation status. `remoteGeneration` exists on `HostStateSnapshot` in `SpeakSwiftlyServer` 12.0.0, but SayBar cannot read it without bypassing the app-facing `EmbeddedServer` model. Generation queue controls are tracked upstream in `SpeakSwiftlyServer#126` so SayBar can keep using direct embedded ownership instead of adding local HTTP or MCP side channels.

The standalone install and retained-log helpers are intentionally not implemented in this SayBar pass. In `SpeakSwiftlyServer` 12.0.0, those helpers still live outside the embedded library contract SayBar imports. Adopting them would widen the product from embedded-runtime-first into app-managed standalone-server behavior.
