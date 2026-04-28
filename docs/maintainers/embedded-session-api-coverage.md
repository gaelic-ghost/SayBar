# Embedded Session API Coverage

## Source Of Truth

This matrix audits SayBar against the embedded app-facing API exposed by `SpeakSwiftlyServer` `4.3.10`, resolved in `SayBar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

The current SayBar product baseline is still embedded-runtime-first. That means `EmbeddedServer` is in scope for active app behavior, while standalone LaunchAgent install helpers remain future-scope until SayBar intentionally grows an app-managed standalone-server mode.

## Coverage Matrix

| API surface | Available from | SayBar coverage | Current SayBar use |
| --- | --- | --- | --- |
| `EmbeddedServer` | `SpeakSwiftlyServer` | Implemented | One long-lived observable app model owned by `SayBarApp` and passed directly into menu bar and Settings scenes. |
| `EmbeddedServer.Options.port` | `EmbeddedServer.Options` | Implemented | Pins the embedded HTTP transport to port `7339`. |
| `EmbeddedServer.Options.runtimeProfileRootURL` | `EmbeddedServer.Options` | Implemented | Points the embedded runtime at SayBar-owned Application Support profile storage. |
| `EmbeddedServer.init(options:)` | `EmbeddedServer` | Implemented | Creates the app-owned embedded runtime model during app initialization. |
| `liftoff(environment:)` | `EmbeddedServer` | Implemented | Starts the embedded runtime on launch unless `--saybar-disable-autostart` is present. |
| `land()` | `EmbeddedServer` | Implemented | Requests graceful embedded runtime shutdown before macOS app termination completes. |
| `overview` | `EmbeddedServer` | Implemented | Drives menu status text, startup-error display, worker readiness, model-loaded state, and default voice fallback. |
| `overview.service` | `HostOverviewSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display the service identifier yet. |
| `overview.environment` | `HostOverviewSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display runtime environment yet. |
| `overview.defaultVoiceProfileName` | `HostOverviewSnapshot` | Implemented | Selects the active voice profile in the menu picker and shows the default profile in Settings. |
| `overview.serverMode` | `HostOverviewSnapshot` | Implemented | Drives high-level ready, degraded, broken, or starting menu status and Settings status. |
| `overview.workerMode` | `HostOverviewSnapshot` | Not surfaced | Available for deeper runtime diagnostics, but SayBar does not display it yet. |
| `overview.workerStage` | `HostOverviewSnapshot` | Implemented | Drives menu status detail and resident-model power-button state. |
| `overview.workerReady` | `HostOverviewSnapshot` | Implemented | Helps decide when the menu can report that the embedded runtime is ready. |
| `overview.startupError` | `HostOverviewSnapshot` | Implemented | Displayed as the highest-priority startup problem in the menu status text. |
| `overview.profileCacheState` | `HostOverviewSnapshot` | Not surfaced | Available for voice-profile diagnostics, but SayBar currently only displays profile list presence. |
| `overview.profileCacheWarning` | `HostOverviewSnapshot` | Not surfaced | Available for voice-profile diagnostics, but SayBar does not display cache warning text yet. |
| `overview.profileCount` | `HostOverviewSnapshot` | Not surfaced | Available for diagnostics, but SayBar derives picker state from `voiceProfiles` directly. |
| `overview.lastProfileRefreshAt` | `HostOverviewSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not show refresh timestamps yet. |
| `generationQueue` | `EmbeddedServer` | Implemented, partial | Menu shows active plus queued generation count as an eight-slot indicator; Settings shows the numeric count. |
| `generationQueue.queueType` | `QueueStatusSnapshot` | Not surfaced | Available for diagnostics, but the menu already labels this queue as generation work. |
| `generationQueue.activeCount` | `QueueStatusSnapshot` | Implemented | Contributes to the menu queue indicator and Settings generation queue count. |
| `generationQueue.queuedCount` | `QueueStatusSnapshot` | Implemented | Contributes to the menu queue indicator and Settings generation queue count. |
| `generationQueue.activeRequest` | `QueueStatusSnapshot` | Not surfaced | Available for request-level diagnostics, but SayBar does not show generation request details yet. |
| `generationQueue.activeRequests` | `QueueStatusSnapshot` | Not surfaced | Available for request-level diagnostics, but SayBar does not list active generation requests yet. |
| `generationQueue.queuedRequests` | `QueueStatusSnapshot` | Not surfaced | Available for request-level diagnostics, but SayBar does not list queued generation requests yet. |
| `playbackQueue` | `EmbeddedServer` | Implemented, partial | Settings shows active plus queued playback count. |
| `playbackQueue.queueType` | `QueueStatusSnapshot` | Not surfaced | Available for diagnostics, but Settings already labels this count as playback queue work. |
| `playbackQueue.activeCount` | `QueueStatusSnapshot` | Implemented | Contributes to the Settings playback queue count. |
| `playbackQueue.queuedCount` | `QueueStatusSnapshot` | Implemented | Contributes to the Settings playback queue count. |
| `playbackQueue.activeRequest` | `QueueStatusSnapshot` | Not surfaced | Available for playback request diagnostics, but SayBar currently uses `playback.activeRequest` for active playback text. |
| `playbackQueue.activeRequests` | `QueueStatusSnapshot` | Not surfaced | Available for request-level diagnostics, but SayBar does not list active playback requests yet. |
| `playbackQueue.queuedRequests` | `QueueStatusSnapshot` | Not surfaced | Available for request-level diagnostics, but SayBar does not list queued playback requests yet. |
| `playback` | `EmbeddedServer` | Implemented, partial | Drives menu playback headline, detail text, and pause/resume/clipboard button behavior. |
| `playback.state` | `PlaybackStatusSnapshot` | Implemented | Switches menu wording and playback button icon between pause, resume, and clipboard speech. |
| `playback.activeRequest` | `PlaybackStatusSnapshot` | Implemented, partial | Menu detail displays the active playback request identifier when playback is active. |
| `playback.isStableForConcurrentGeneration` | `PlaybackStatusSnapshot` | Not surfaced | Available for richer buffering/concurrency diagnostics, but SayBar does not display it yet. |
| `playback.isRebuffering` | `PlaybackStatusSnapshot` | Not surfaced | Available for richer playback diagnostics, but SayBar does not display rebuffering state yet. |
| `playback.stableBufferedAudioMS` | `PlaybackStatusSnapshot` | Not surfaced | Available for playback buffering diagnostics, but SayBar does not display buffer duration yet. |
| `playback.stableBufferTargetMS` | `PlaybackStatusSnapshot` | Not surfaced | Available for playback buffering diagnostics, but SayBar does not display target buffer duration yet. |
| `runtimeRefresh` | `EmbeddedServer` | Not surfaced | Available for refresh-cycle diagnostics, but SayBar does not show refresh timing yet. |
| `runtimeRefresh.sequenceID` | `RuntimeRefreshSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display refresh sequence identifiers yet. |
| `runtimeRefresh.source` | `RuntimeRefreshSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display refresh source yet. |
| `runtimeRefresh.startedAt` | `RuntimeRefreshSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display refresh start time yet. |
| `runtimeRefresh.generationQueueRefreshedAt` | `RuntimeRefreshSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display queue refresh timing yet. |
| `runtimeRefresh.playbackQueueRefreshedAt` | `RuntimeRefreshSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display queue refresh timing yet. |
| `runtimeRefresh.playbackStateRefreshedAt` | `RuntimeRefreshSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display playback refresh timing yet. |
| `runtimeRefresh.completedAt` | `RuntimeRefreshSnapshot` | Not surfaced | Available for diagnostics, but SayBar does not display refresh completion time yet. |
| `runtimeBackendTransition` | `EmbeddedServer` | Not surfaced | Available for backend-switch progress, but SayBar currently only shows a local busy flag and completion/error message. |
| `runtimeBackendTransition.state` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for backend transition UI, but SayBar does not show it yet. |
| `runtimeBackendTransition.activeSpeechBackend` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for transition diagnostics; SayBar uses `runtimeConfiguration.activeRuntimeSpeechBackend` for the picker. |
| `runtimeBackendTransition.requestedSpeechBackend` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for transition diagnostics, but SayBar does not show pending backend requests yet. |
| `runtimeBackendTransition.requestID` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for transition diagnostics, but SayBar does not show backend switch request identifiers yet. |
| `runtimeBackendTransition.operation` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for transition diagnostics, but SayBar does not show backend switch operation labels yet. |
| `runtimeBackendTransition.waitingReason` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for transition diagnostics, but SayBar does not show waiting reasons yet. |
| `runtimeBackendTransition.submittedAt` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for transition diagnostics, but SayBar does not show submission time yet. |
| `runtimeBackendTransition.startedAt` | `RuntimeBackendTransitionSnapshot` | Not surfaced | Available for transition diagnostics, but SayBar does not show start time yet. |
| `currentGenerationJobs` | `EmbeddedServer` | Not surfaced | Available for live generation progress, but SayBar does not list active generation jobs yet. |
| `currentGenerationJobs[].jobID` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for job diagnostics, but SayBar does not show generation job identifiers yet. |
| `currentGenerationJobs[].op` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for job diagnostics, but SayBar does not show generation operations yet. |
| `currentGenerationJobs[].profileName` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for job diagnostics, but SayBar does not show per-job profile names yet. |
| `currentGenerationJobs[].submittedAt` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for job diagnostics, but SayBar does not show submission time yet. |
| `currentGenerationJobs[].startedAt` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for job diagnostics, but SayBar does not show start time yet. |
| `currentGenerationJobs[].latestStage` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for progress UI, but SayBar does not show generation stages yet. |
| `currentGenerationJobs[].elapsedGenerationSeconds` | `CurrentGenerationJobSnapshot` | Not surfaced | Available for progress UI, but SayBar does not show elapsed generation time yet. |
| `runtimeConfiguration` | `EmbeddedServer` | Implemented, partial | Settings displays the active backend; menu backend picker reads the active backend. |
| `runtimeConfiguration.activeRuntimeSpeechBackend` | `RuntimeConfigurationSnapshot` | Implemented | Drives the backend picker selection and Settings speech backend value. |
| `runtimeConfiguration.nextRuntimeSpeechBackend` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for next-start diagnostics, but SayBar does not show pending backend configuration yet. |
| `runtimeConfiguration.activeQwenResidentModel` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for model diagnostics, but SayBar does not show active Qwen model yet. |
| `runtimeConfiguration.nextQwenResidentModel` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for next-start diagnostics, but SayBar does not show next Qwen model yet. |
| `runtimeConfiguration.activeMarvisResidentPolicy` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for model diagnostics, but SayBar does not show active Marvis policy yet. |
| `runtimeConfiguration.nextMarvisResidentPolicy` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for next-start diagnostics, but SayBar does not show next Marvis policy yet. |
| `runtimeConfiguration.activeDefaultVoiceProfileName` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for runtime configuration diagnostics; SayBar uses `overview.defaultVoiceProfileName` instead. |
| `runtimeConfiguration.nextDefaultVoiceProfileName` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for next-start diagnostics, but SayBar does not show next default profile yet. |
| `runtimeConfiguration.environmentSpeechBackendOverride` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show environment overrides yet. |
| `runtimeConfiguration.environmentQwenResidentModelOverride` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show environment overrides yet. |
| `runtimeConfiguration.persistedSpeechBackend` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted backend yet. |
| `runtimeConfiguration.persistedQwenResidentModel` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted model yet. |
| `runtimeConfiguration.persistedMarvisResidentPolicy` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted Marvis policy yet. |
| `runtimeConfiguration.persistedDefaultVoiceProfileName` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted default profile yet. |
| `runtimeConfiguration.profileRootPath` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show profile storage paths yet. |
| `runtimeConfiguration.persistedConfigurationPath` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted configuration path yet. |
| `runtimeConfiguration.persistedConfigurationExists` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted configuration existence yet. |
| `runtimeConfiguration.persistedConfigurationState` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted configuration state yet. |
| `runtimeConfiguration.persistedConfigurationError` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show persisted configuration errors yet. |
| `runtimeConfiguration.persistedConfigurationAppliesOnRestart` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show restart-application semantics yet. |
| `runtimeConfiguration.activeRuntimeMatchesNextRuntime` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show active-vs-next runtime drift yet. |
| `runtimeConfiguration.persistedConfigurationWillAffectNextRuntimeStart` | `RuntimeConfigurationSnapshot` | Not surfaced | Available for configuration diagnostics, but SayBar does not show next-start impact yet. |
| `voiceProfiles` | `EmbeddedServer` | Implemented | Populates the menu voice-profile picker and disables the picker when no profiles are cached. |
| `voiceProfiles[].profileName` | `ProfileSnapshot` | Implemented | Displayed as each picker option and used as the picker tag. |
| `voiceProfiles[].vibe` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show profile vibe yet. |
| `voiceProfiles[].createdAt` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show profile creation time yet. |
| `voiceProfiles[].voiceDescription` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show voice descriptions yet. |
| `voiceProfiles[].sourceText` | `ProfileSnapshot` | Not surfaced | Available for richer profile UI, but SayBar does not show source text yet. |
| `transports` | `EmbeddedServer` | Implemented, partial | Settings lists transport name plus state/address/path summary. |
| `transports[].name` | `TransportStatusSnapshot` | Implemented | Displayed as the transport row headline in Settings. |
| `transports[].enabled` | `TransportStatusSnapshot` | Not surfaced | Available for transport diagnostics, but SayBar does not show enabled state yet. |
| `transports[].state` | `TransportStatusSnapshot` | Implemented | Displayed in each transport summary. |
| `transports[].host` | `TransportStatusSnapshot` | Implemented | Used to compose each transport address summary. |
| `transports[].port` | `TransportStatusSnapshot` | Implemented | Used to compose each transport address summary. |
| `transports[].path` | `TransportStatusSnapshot` | Implemented | Used to compose each transport path summary. |
| `transports[].advertisedAddress` | `TransportStatusSnapshot` | Not surfaced | Available for diagnostics, but SayBar composes host, port, and path directly today. |
| `recentErrors` | `EmbeddedServer` | Implemented, partial | Menu uses the newest error message as high-priority status detail; Settings lists retained errors. |
| `recentErrors[].occurredAt` | `RecentErrorSnapshot` | Not surfaced | Available for error diagnostics, but SayBar does not display timestamps yet. |
| `recentErrors[].source` | `RecentErrorSnapshot` | Implemented | Displayed as the Settings error row headline. |
| `recentErrors[].code` | `RecentErrorSnapshot` | Not surfaced | Available for error diagnostics, but SayBar does not display error codes yet. |
| `recentErrors[].message` | `RecentErrorSnapshot` | Implemented | Displayed in menu status detail and Settings error row detail. |
| `listVoiceProfiles()` | `EmbeddedServer` | Not used | Redundant for current UI because SwiftUI reads the observable `voiceProfiles` property directly. |
| `refreshVoiceProfiles()` | `EmbeddedServer` | Implemented | Called after startup and when the menu opens with an empty profile cache. |
| `queueLiveSpeech(text:profileName:textProfileID:normalizationContext:sourceFormat:requestContext:qwenPreModelTextChunking:)` | `EmbeddedServer` | Implemented, basic | Menu playback button queues trimmed clipboard text while leaving profile, text profile, normalization, source format, request context, and chunking options at their defaults. |
| `setDefaultVoiceProfileName(_:)` | `EmbeddedServer` | Implemented | Voice-profile picker updates the embedded host's default voice profile. |
| `clearDefaultVoiceProfileName()` | `EmbeddedServer` | Not used | Available for a future reset/default-profile UI action. |
| `switchSpeechBackend(to:)` | `EmbeddedServer` | Implemented | Speech-backend picker switches the running runtime backend. |
| `reloadModels()` | `EmbeddedServer` | Implemented | Resident-model power control reloads runtime models when models are unloaded. |
| `unloadModels()` | `EmbeddedServer` | Implemented | Resident-model power control unloads runtime models when models are loaded. |
| `pausePlayback()` | `EmbeddedServer` | Implemented | Playback control pauses active playback. |
| `resumePlayback()` | `EmbeddedServer` | Implemented | Playback control resumes paused playback. |
| `clearPlaybackQueue()` | `EmbeddedServer` | Not used | Available for a future playback queue clear action. |
| `cancelPlaybackRequest(_:)` | `EmbeddedServer` | Not used | Available for future request-level playback cancellation. |
| `ActiveRequestSnapshot.id` | Queue and playback snapshots | Implemented, partial | Displayed for the active playback request in menu detail; not listed for generation queues yet. |
| `ActiveRequestSnapshot.op` | Queue and playback snapshots | Not surfaced | Available for request diagnostics, but SayBar does not show request operations yet. |
| `ActiveRequestSnapshot.profileName` | Queue and playback snapshots | Not surfaced | Available for request diagnostics, but SayBar does not show per-request profile names yet. |
| `QueuedRequestSnapshot.id` | Queue snapshots | Not surfaced | Available for request diagnostics and cancellation UI, but SayBar does not list queued requests yet. |
| `QueuedRequestSnapshot.op` | Queue snapshots | Not surfaced | Available for request diagnostics, but SayBar does not show queued request operations yet. |
| `QueuedRequestSnapshot.profileName` | Queue snapshots | Not surfaced | Available for request diagnostics, but SayBar does not show queued request profile names yet. |
| `QueuedRequestSnapshot.queuePosition` | Queue snapshots | Not surfaced | Available for request diagnostics, but SayBar does not show queue positions yet. |
| `HostStateSnapshot` | Control action returns | Consumed indirectly | Backend switch and model load/unload actions apply refreshed host state inside `EmbeddedServer`; SayBar reads the updated observable properties afterward. |
| `HostStateSnapshot.overview` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer` after backend/model actions; SayBar observes `server.overview`. |
| `HostStateSnapshot.runtimeRefresh` | `HostStateSnapshot` | Consumed indirectly, not surfaced | Applied by `EmbeddedServer`; SayBar does not display refresh details yet. |
| `HostStateSnapshot.generationQueue` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; SayBar observes queue counts. |
| `HostStateSnapshot.playbackQueue` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; Settings observes playback queue count. |
| `HostStateSnapshot.playback` | `HostStateSnapshot` | Consumed indirectly | Applied by `EmbeddedServer`; SayBar observes playback state. |
| `HostStateSnapshot.runtimeBackendTransition` | `HostStateSnapshot` | Consumed indirectly, not surfaced | Applied by `EmbeddedServer`; SayBar does not display backend transition details yet. |
| `HostStateSnapshot.currentGenerationJobs` | `HostStateSnapshot` | Consumed indirectly, not surfaced | Applied by `EmbeddedServer`; SayBar does not display job progress yet. |
| `HostStateSnapshot.runtimeConfiguration` | `HostStateSnapshot` | Consumed indirectly, partial | Applied by `EmbeddedServer`; SayBar reads the active backend value. |
| `HostStateSnapshot.transports` | `HostStateSnapshot` | Consumed indirectly, partial | Applied by `EmbeddedServer`; Settings displays transport diagnostics. |
| `HostStateSnapshot.recentErrors` | `HostStateSnapshot` | Consumed indirectly, partial | Applied by `EmbeddedServer`; menu and Settings display retained error messages. |
| `ServerInstallLayout` | `SpeakSwiftlyServer` | Intentionally not used | Future app-managed standalone-server path contract; out of current embedded-runtime baseline. |
| `ServerInstallLayout.defaultForCurrentUser(...)` | `ServerInstallLayout` | Intentionally not used | Future default path resolver for standalone LaunchAgent-backed installs. |
| `ServerInstallLayout.launchAgentLabel` | `ServerInstallLayout` | Intentionally not used | Future standalone install metadata. |
| `ServerInstallLayout.workingDirectoryURL` | `ServerInstallLayout` | Intentionally not used | Future standalone process working directory. |
| `ServerInstallLayout.applicationSupportDirectoryURL` | `ServerInstallLayout` | Intentionally not used | Future standalone durable support root. |
| `ServerInstallLayout.cacheDirectoryURL` | `ServerInstallLayout` | Intentionally not used | Future standalone cache root. |
| `ServerInstallLayout.logsDirectoryURL` | `ServerInstallLayout` | Intentionally not used | Future standalone retained-log directory. |
| `ServerInstallLayout.launchAgentsDirectoryURL` | `ServerInstallLayout` | Intentionally not used | Future standalone LaunchAgents directory. |
| `ServerInstallLayout.launchAgentPlistURL` | `ServerInstallLayout` | Intentionally not used | Future standalone LaunchAgent plist path. |
| `ServerInstallLayout.serverConfigFileURL` | `ServerInstallLayout` | Intentionally not used | Future standalone server config path. |
| `ServerInstallLayout.launchAgentConfigAliasURL` | `ServerInstallLayout` | Intentionally not used | Future compatibility path for older LaunchAgent config aliases. |
| `ServerInstallLayout.runtimeBaseDirectoryURL` | `ServerInstallLayout` | Intentionally not used | Future standalone runtime state root. |
| `ServerInstallLayout.runtimeProfileRootURL` | `ServerInstallLayout` | Intentionally not used | Future standalone profile storage root; current embedded mode uses `EmbeddedServer.Options.runtimeProfileRootURL`. |
| `ServerInstallLayout.runtimeConfigurationFileURL` | `ServerInstallLayout` | Intentionally not used | Future standalone persisted runtime configuration path. |
| `ServerInstallLayout.standardOutLogURL` | `ServerInstallLayout` | Intentionally not used | Future retained stdout log path. |
| `ServerInstallLayout.standardErrorLogURL` | `ServerInstallLayout` | Intentionally not used | Future retained stderr log path. |
| `ServerInstalledLogKind.stdout` | `ServerInstalledLogKind` | Intentionally not used | Future retained stdout log selection. |
| `ServerInstalledLogKind.stderr` | `ServerInstalledLogKind` | Intentionally not used | Future retained stderr log selection. |
| `ServerInstalledLogFileSnapshot` | `SpeakSwiftlyServer` | Intentionally not used | Future retained-log display or diagnostics. |
| `ServerInstalledLogFileSnapshot.kind` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future retained-log stream labeling. |
| `ServerInstalledLogFileSnapshot.fileURL` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future retained-log file location display. |
| `ServerInstalledLogFileSnapshot.exists` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future retained-log availability display. |
| `ServerInstalledLogFileSnapshot.text` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future retained-log text display. |
| `ServerInstalledLogFileSnapshot.lines` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future retained-log line display. |
| `ServerInstalledLogFileSnapshot.jsonLineTexts` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future structured retained-log diagnostics. |
| `ServerInstalledLogFileSnapshot.totalLineCount` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future retained-log truncation display. |
| `ServerInstalledLogFileSnapshot.truncatedLineCount` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future retained-log truncation display. |
| `ServerInstalledLogFileSnapshot.decodeJSONLines(as:decoder:)` | `ServerInstalledLogFileSnapshot` | Intentionally not used | Future structured retained-log decoding. |
| `ServerInstalledLogsSnapshot` | `SpeakSwiftlyServer` | Intentionally not used | Future combined stdout/stderr diagnostics for standalone installs. |
| `ServerInstalledLogsSnapshot.layout` | `ServerInstalledLogsSnapshot` | Intentionally not used | Future retained-log context for standalone installs. |
| `ServerInstalledLogsSnapshot.stdout` | `ServerInstalledLogsSnapshot` | Intentionally not used | Future retained stdout diagnostics. |
| `ServerInstalledLogsSnapshot.stderr` | `ServerInstalledLogsSnapshot` | Intentionally not used | Future retained stderr diagnostics. |
| `ServerInstalledLogsSnapshot.file(for:)` | `ServerInstalledLogsSnapshot` | Intentionally not used | Future retained-log stream lookup. |
| `ServerInstalledLogs.read(layout:maximumLineCount:)` | `ServerInstalledLogs` | Intentionally not used | Future retained stdout/stderr snapshot loading for standalone installs. |

## Coverage Summary

SayBar covers the core embedded-session baseline: app-owned lifecycle, observable status, queue counts, playback state, transport diagnostics, recent errors, voice profile refresh and selection, speech backend switching, resident model load/unload, playback pause/resume, and clipboard-to-speech submission.

The main embedded-session gaps are deeper operator controls and diagnostics: request-level queue views, playback queue clear/cancel actions, backend transition progress, generation job progress, refresh timing, profile metadata, buffering details, and full runtime configuration inspection.

The standalone install and retained-log helpers are intentionally not implemented in SayBar yet. They are available package APIs, but adopting them would widen the product from embedded-runtime-first into app-managed standalone-server behavior.
