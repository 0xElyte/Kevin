# Implementation Plan: Project Kevin

## Overview

Implement Project Kevin as a Flutter/Dart application targeting Android and Windows. Tasks are sequenced so each step builds on the previous: scaffolding → theme → UI shell → core flows → integrations → background service → settings → tests. All code is Dart/Flutter unless otherwise noted.

---

## Tasks

- [x] 1. Project scaffolding and dependency setup
  - Create a new Flutter project with Android and Windows targets enabled
  - Add all required dependencies to `pubspec.yaml`: `flutter_foreground_task`, `permission_handler`, `just_audio`, `record`, `google_fonts`, `porcupine_flutter`, `http`, `dio`, `shared_preferences`, `connectivity_plus`, `uuid`
  - Create the top-level folder structure: `lib/core/`, `lib/features/chat/`, `lib/features/settings/`, `lib/features/wake_word/`, `lib/services/`, `lib/os_bridge/`, `lib/theme/`
  - Add `assets/hey-kevin.ppn` placeholder and register the `assets/` directory in `pubspec.yaml`
  - _Requirements: 1.1, 1.2_

- [x] 2. SciFi_Theme implementation
  - [x] 2.1 Define theme tokens and `ThemeData`
    - Create `lib/theme/scifi_theme.dart` with all design tokens (`colorBackground`, `colorSurface`, `colorAccent`, `colorAccentDim`, `colorTextPrimary`, `colorTextSecondary`, `colorBorderUser`, `colorBorderKevin`, `borderRadius`, `bubblePadding`)
    - Load Orbitron (headings) and Exo 2 (body) via `google_fonts` and wire into `ThemeData`
    - Force dark theme regardless of system color scheme setting
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.8_

  - [x] 2.2 Create reusable themed widgets
    - Implement `SciFiButton`, `SciFiTextField`, `SciFiCard` widgets that consume theme tokens
    - _Requirements: 14.5, 14.7_

  - [x] 2.3 Write widget tests for SciFi_Theme application
    - Verify `colorBackground`, `colorAccent`, Orbitron/Exo 2 fonts are applied to key widgets
    - _Requirements: 14.1, 14.2, 14.3, 14.4_

- [x] 3. Data models
  - [x] 3.1 Implement core data models
    - Create `Message`, `MessageRole`, `MessageType`, `MessageStatus` in `lib/core/models/message.dart`
    - Create `AppSettings`, `ResponseMode` in `lib/core/models/app_settings.dart`
    - Create `SuggestionCard`, `SuggestionCategory` in `lib/core/models/suggestion_card.dart`
    - Create `WakeWordEvent` in `lib/core/models/wake_word_event.dart`
    - Create `AIResponse`, `AIIntent`, `OSActionSpec`, `ElevenLabsGenerationSpec` in `lib/core/models/ai_response.dart`
    - Create `OSActionResult`, `SettingsTarget` in `lib/core/models/os_action.dart`
    - _Requirements: 2.1, 5.1, 6.3, 11.1_

  - [x] 3.2 Write property test for ResponseMode persistence round-trip (Property 3)
    - **Property 3: ResponseMode Persists Across Restarts**
    - **Validates: Requirements 5.4**

  - [x] 3.3 Write unit tests for Message model serialization
    - Test all `MessageRole`, `MessageType`, `MessageStatus` enum values
    - _Requirements: 2.2, 2.3_

- [x] 4. App settings and persistence
  - [x] 4.1 Implement `AppSettings` persistence with SharedPreferences
    - Create `lib/services/settings_service.dart` implementing read/write for all `AppSettings` fields
    - Persist `ResponseMode`, `wakeWordEnabled`, `wakeWordSensitivity`, `elevenLabsApiKey`, `aiApiKey`, `ttsVoiceId`
    - _Requirements: 5.4, 17.1_

  - [x] 4.2 Write property test for ResponseMode persistence (Property 3)
    - **Property 3: ResponseMode Persists Across Restarts**
    - Use a mock SharedPreferences; write any `ResponseMode` value, simulate restart, verify read-back equals written value
    - **Validates: Requirements 5.4**

  - [x] 4.3 Write unit tests for AppSettings persistence
    - Test default values, write/read round-trip for all fields
    - _Requirements: 5.4_

- [x] 5. Connectivity guard and error handling infrastructure
  - [x] 5.1 Implement `ConnectivityGuard`
    - Create `lib/core/connectivity_guard.dart` with `withConnectivity<T>()` — checks connectivity, applies 10s timeout, throws `OfflineException` or `TimeoutException`
    - Define all custom exception types: `OfflineException`, `TimeoutException`, `STTTranscriptionError`, `TTSSynthesisError`, `OSActionError`, `FileTooLargeError`, `UnsupportedFileTypeError`, `CharacterLimitError`, `AudioTooShortError`
    - _Requirements: 10.1, 10.2_

  - [x] 5.2 Write unit tests for `ConnectivityGuard`
    - Test offline path, timeout path, and successful path
    - _Requirements: 10.1, 10.2_

- [x] 6. Input validation logic
  - [x] 6.1 Implement input validation functions
    - Create `lib/core/input_validator.dart` with `validateTextInput(String text)` (empty check, 2000-char limit) and `validateAudioDuration(Duration d)` (≥ 0.5s check) and `validateFileAttachment(String mimeType, int sizeBytes)`
    - _Requirements: 3.2, 3.3, 4.6, 8.4, 8.5_

  - [x] 6.2 Write property test for character limit enforcement (Property 7)
    - **Property 7: Character Limit Enforced on Text Input**
    - For any string with `length > 2000`, `validateTextInput` returns a `CharacterLimitError`; for `length ≤ 2000` and non-empty, returns valid
    - **Validates: Requirements 3.3**

  - [x] 6.3 Write property test for file attachment constraints (Property 8)
    - **Property 8: File Attachment Constraints Enforced**
    - For any file `size > 10 MB`, returns `FileTooLargeError`; for unsupported MIME type, returns `UnsupportedFileTypeError`; valid files are accepted
    - **Validates: Requirements 8.4, 8.5**

  - [x] 6.4 Write property test for short audio clip discard (Property 6)
    - **Property 6: Short Audio Clips Are Discarded Without STT Submission**
    - For any `Duration < 0.5s`, `validateAudioDuration` returns `AudioTooShortError` and STT is not called
    - **Validates: Requirements 4.6, 11.8**

  - [x] 6.5 Write unit tests for input validation edge cases
    - Test boundary values: exactly 2000 chars, exactly 0.5s, exactly 10 MB
    - _Requirements: 3.2, 3.3, 4.6, 8.4, 8.5_

- [x] 7. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. AI Engine
  - [x] 8.1 Implement `AIEngine` REST client
    - Create `lib/services/ai_engine.dart` implementing `IAIEngine`
    - Send system prompt instructing GPT-4o to return structured JSON with `intent`, `response_text`, `os_action`, `generation_spec`
    - Parse JSON response into `AIResponse`
    - Wrap all calls in `ConnectivityGuard`
    - _Requirements: 7.1, 6.1_

  - [x] 8.2 Implement intent classification routing
    - Route `AIIntent.osAction` → `OS_Bridge`
    - Route `AIIntent.elevenLabsTTS` → `TTS_Service`
    - Route `AIIntent.elevenLabsMusic` → `Music_Service`
    - Route `AIIntent.elevenLabsSFX` → `SFX_Service`
    - Route `AIIntent.generalQuery` → render text/voice response
    - _Requirements: 6.1, 7.1, 9.1_

  - [x] 8.3 Write unit tests for AI_Engine intent classification
    - Mock LLM responses for each intent type; verify correct `AIIntent` is returned
    - Test `os_action` JSON parsing, `generation_spec` parsing
    - _Requirements: 6.1, 7.1_

- [x] 9. OS Bridge
  - [x] 9.1 Implement `AndroidOSBridge`
    - Create `lib/os_bridge/android_os_bridge.dart` implementing `IOSBridge`
    - Implement `openApp` via `PackageManager` fuzzy match + `Intent.ACTION_MAIN`
    - Implement `navigateToSettings` with full `SettingsTarget` → `android.settings.*` mapping
    - _Requirements: 6.2, 6.3_

  - [x] 9.2 Implement `WindowsOSBridge`
    - Create `lib/os_bridge/windows_os_bridge.dart` implementing `IOSBridge`
    - Implement `openApp` via `Process.run` / ShellExecute
    - Implement `navigateToSettings` with full `SettingsTarget` → `ms-settings:` URI mapping
    - _Requirements: 6.2, 6.3_

  - [x] 9.3 Wire `OS_Bridge` factory
    - Create `lib/os_bridge/os_bridge_factory.dart` returning `AndroidOSBridge` or `WindowsOSBridge` based on `Platform`
    - _Requirements: 6.1_

  - [x] 9.4 Write property test for OS action target mapping (Property 4)
    - **Property 4: OS Action Target Maps to Correct Platform Command**
    - For every `SettingsTarget` value, verify Android bridge produces correct `android.settings.*` string and Windows bridge produces correct `ms-settings:` URI
    - **Validates: Requirements 6.2, 6.3**

  - [x] 9.5 Write property test for OS action result feedback (Property 5)
    - **Property 5: OS Action Result Always Produces User Feedback**
    - For any `OSActionResult` (success or failure), verify a non-empty feedback message is produced
    - **Validates: Requirements 6.4, 6.5**

  - [x] 9.6 Write unit tests for OS_Bridge action mapping
    - Test each `SettingsTarget` on both platforms; test `openApp` success and failure paths
    - _Requirements: 6.2, 6.3, 6.4, 6.5_

- [x] 10. ElevenLabs client
  - [x] 10.1 Implement `ElevenLabsClient` — STT (batch)
    - Create `lib/services/elevenlabs_client.dart` implementing `IElevenLabsClient`
    - Implement `transcribe(Uint8List audioBytes)` via `POST /v1/speech-to-text` with `model_id: scribe_v2`
    - Wrap in `ConnectivityGuard`
    - _Requirements: 4.2, 4.3_

  - [x] 10.2 Implement STT Realtime WebSocket (Scribe v2 Realtime)
    - Add `transcribeRealtime(Stream<Uint8List> audioStream)` to `ElevenLabsClient`
    - Connect to `wss://api.elevenlabs.io/v1/speech-to-text/stream`, stream PCM chunks, collect final transcript
    - _Requirements: 11.5, 11.6_

  - [x] 10.3 Implement TTS streaming
    - Add `synthesizeSpeech(String text, String voiceId)` returning `Stream<Uint8List>` via `POST /v1/text-to-speech/{voice_id}/stream`
    - _Requirements: 9.1, 9.2_

  - [x] 10.4 Implement Music generation
    - Add `generateMusic(String prompt)` via `POST /v1/music` with async polling until complete, then download MP3
    - _Requirements: 15.2 (ElevenLabs category)_

  - [x] 10.5 Implement Sound Effects generation
    - Add `generateSoundEffect(String prompt)` via `POST /v1/sound-generation`, return binary MP3 bytes
    - _Requirements: 15.2 (ElevenLabs category)_

- [x] 11. Audio playback
  - [x] 11.1 Implement TTS streaming playback with `just_audio`
    - Create `lib/services/audio_player_service.dart`
    - Pipe `Stream<Uint8List>` from TTS into `just_audio`'s `StreamAudioSource` for low-latency playback
    - _Requirements: 9.2, 9.3_

  - [x] 11.2 Implement MP3 file playback for Music and SFX
    - Add `playBytes(Uint8List mp3Bytes)` to `AudioPlayerService` using `just_audio`
    - _Requirements: 9.2_

- [x] 12. Chat UI — core widgets
  - [x] 12.1 Implement `UserBubble` widget
    - Right-aligned bubble, red border, SciFi_Theme styling
    - _Requirements: 2.2, 14.5_

  - [x] 12.2 Implement `KevinBubble` widget
    - Left-aligned bubble, dark background, red left accent border, SciFi_Theme styling
    - Show loading indicator (`MessageStatus.sending`) and error state (`MessageStatus.error`) with retry button
    - _Requirements: 2.3, 10.3, 14.5_

  - [x] 12.3 Implement `VoiceNoteBubble` widget
    - Waveform placeholder + play/pause button; uses `AudioPlayerService` for playback
    - Show playing indicator while audio is active
    - _Requirements: 2.7, 9.3_

  - [x] 12.4 Write property test for message bubble alignment (Property 1)
    - **Property 1: Message Bubble Alignment Matches Role**
    - For any `Message` with `role == user`, widget is right-aligned; for `role == kevin`, widget is left-aligned
    - **Validates: Requirements 2.2, 2.3**

- [x] 13. Chat UI — `ConversationView` and empty state
  - [x] 13.1 Implement `SuggestionCard` widget
    - Black background, red 1dp border, 8dp corner radius, Orbitron label, Exo 2 sub-label
    - Tap handler populates `InputBar` text field with `promptText`
    - _Requirements: 15.1, 15.3, 15.7_

  - [x] 13.2 Implement `SuggestionCardGrid`
    - 2-column `Wrap` layout displaying all 8 default `SuggestionCard` instances
    - _Requirements: 15.1, 15.2_

  - [x] 13.3 Implement `ConversationView`
    - Scrollable `ListView` of `Message` widgets
    - Show `SuggestionCardGrid` when message list is empty; hide when ≥1 message exists
    - Auto-scroll to most recent message on new additions
    - _Requirements: 2.1, 2.8, 15.1, 15.5, 15.6_

  - [x] 13.4 Write property test for suggestion card / message mutual exclusion (Property 15)
    - **Property 15: Messages Present Implies No Suggestion Cards**
    - For any non-empty message list, zero `SuggestionCard` widgets rendered; for empty list, ≥6 rendered
    - **Validates: Requirements 15.1, 15.5, 15.6**

  - [~] 13.5 Write property test for suggestion card tap populates input (Property 14)
    - **Property 14: Suggestion Card Tap Populates Input Field**
    - For any `SuggestionCard`, tapping it sets `InputBar` text to exactly `card.promptText`
    - **Validates: Requirements 15.3**

  - [~] 13.6 Write widget tests for `ConversationView`
    - Empty state shows ≥6 suggestion cards; active state hides them; auto-scroll on new message
    - _Requirements: 2.1, 2.8, 15.1, 15.5, 15.6_

- [x] 14. Chat UI — `InputBar` and `ResponseModeToggle`
  - [x] 14.1 Implement `InputBar`
    - `AttachButton` (left), `TextField` (center, 2000-char limit with inline counter), `VoiceButton` (right of field), `SendButton` (rightmost)
    - Disable `SendButton` when text field is empty
    - Show inline red error when character limit exceeded
    - File attachment: open native file picker, validate file, display selected filename
    - _Requirements: 2.4, 2.5, 2.6, 3.2, 3.3, 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x] 14.2 Implement `ResponseModeToggle`
    - Voice / Text toggle switch, reads/writes `ResponseMode` via `SettingsService`
    - _Requirements: 5.1, 5.4, 5.5_

  - [~] 14.3 Write property test for response delivery mode (Property 2)
    - **Property 2: Response Delivery Mode Matches Active ResponseMode**
    - For `ResponseMode.voice`, TTS pipeline is invoked; for `ResponseMode.text`, text bubble rendered and TTS not called
    - **Validates: Requirements 5.2, 5.3**

  - [~] 14.4 Write widget tests for `InputBar`
    - Send button disabled when empty; enabled when non-empty; character limit error shown at 2001 chars
    - _Requirements: 3.2, 3.3_

  - [~] 14.5 Write widget test for `ResponseModeToggle` persistence
    - Toggle persists selection across widget rebuilds
    - _Requirements: 5.4_

- [x] 15. Chat UI — `AppBar` and `ConversationScreen` wiring
  - [x] 15.1 Implement SciFi `AppBar`
    - "KEVIN" title in Orbitron, `ResponseModeToggle` inline, "Quit" button top-right
    - _Requirements: 13.1, 14.1_

  - [x] 15.2 Implement `ConversationScreen`
    - Wire `AppBar`, `ConversationView`, `InputBar` together
    - Connect `InputBar` send → `AI_Engine.process()` → render response per `ResponseMode`
    - Connect `InputBar` voice button → mic capture → STT → `AI_Engine.process()`
    - Show loading indicator (`KevinBubble` in `sending` state) while awaiting response
    - Handle all error types → render error `KevinBubble` with retry
    - _Requirements: 2.1, 3.1, 4.1, 4.2, 4.3, 4.4, 4.5, 10.3_

- [x] 16. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 17. `ListeningToast` and `VoiceInputMeter`
  - [x] 17.1 Implement `VoiceInputMeter` `CustomPainter`
    - Circular arc whose sweep angle maps linearly to RMS audio level (0.0–1.0)
    - Animates at 60fps via `Ticker`; red ring, SciFi_Theme styled
    - _Requirements: 11.4, 14.6_

  - [x] 17.2 Implement `ListeningToast` overlay widget
    - System overlay (shown even when app is in background via `flutter_foreground_task` overlay API)
    - Displays "Kevin is listening..." label and `VoiceInputMeter`
    - SciFi_Theme styled
    - _Requirements: 11.3, 12.4, 14.6_

  - [~] 17.3 Write property test for STT submission dismisses ListeningToast (Property 10)
    - **Property 10: STT Submission Dismisses ListeningToast**
    - For any audio submission event, `ListeningToast` is dismissed before or at the moment of STT call
    - **Validates: Requirements 11.7**

  - [~] 17.4 Write widget tests for `ListeningToast`
    - Appears on `WakeWordEvent`; dismisses on STT submission; `VoiceInputMeter` animates with RMS level
    - _Requirements: 11.3, 11.4, 11.7_

- [x] 18. Wake word detection
  - [x] 18.1 Implement `PorcupineWakeWordDetector`
    - Create `lib/features/wake_word/porcupine_wake_word_detector.dart`
    - Load `hey-kevin.ppn` from assets, configure sensitivity 0.5, expose `Stream<WakeWordEvent>`
    - Implement `start()`, `stop()`, `delete()`
    - _Requirements: 11.1, 12.1_

  - [x] 18.2 Implement silence timeout logic
    - After wake word activation, monitor RMS level; if below threshold for 2 continuous seconds, stop capture and submit to STT
    - Discard and return to listening if captured audio < 0.5s
    - _Requirements: 11.6, 11.8_

  - [~] 18.3 Write property test for wake word triggers ListeningToast and mic capture (Property 9)
    - **Property 9: Wake Word Event Triggers ListeningToast and Mic Capture**
    - For any `WakeWordEvent`, both `ListeningToast` becomes visible and mic capture begins
    - **Validates: Requirements 11.3, 11.5**

  - [~] 18.4 Write property test for silence timeout triggers STT submission (Property 11)
    - **Property 11: Silence Timeout Triggers STT Submission**
    - For any active capture session, 2s of silence below threshold causes STT submission
    - **Validates: Requirements 11.6**

- [x] 19. Kevin_Service — Android foreground service
  - [x] 19.1 Implement Android `Kevin_Service` using `flutter_foreground_task`
    - Create `lib/features/wake_word/kevin_service.dart` implementing `IKevinService`
    - Configure notification channel `kevin_service_channel`, `PRIORITY_LOW`, `ongoing: true`
    - Add "Open Kevin" `PendingIntent` (bring app to foreground) and "Quit" `PendingIntent` (broadcast → `Quit_Action`)
    - Set `START_STICKY` for OS restart within 5 seconds
    - Register `BOOT_COMPLETED` `BroadcastReceiver` to restart service after reboot if wake word was enabled
    - _Requirements: 12.1, 12.2, 12.5, 12.7, 12.8, 12.9, 12.10, 12.11_

  - [x] 19.2 Implement Windows background process / tray
    - System tray icon with "Open Kevin" and "Quit" context menu items
    - Spawn Porcupine in a Dart isolate at app start
    - _Requirements: 12.1, 12.2_

  - [~] 19.3 Write property test for Kevin_Service running implies Wake_Word_Detector active (Property 12)
    - **Property 12: Kevin_Service Running Implies Wake_Word_Detector Active**
    - For any state where `Kevin_Service.isRunning == true`, `Wake_Word_Detector.isActive == true`
    - **Validates: Requirements 12.3**

- [x] 20. Quit_Action
  - [x] 20.1 Implement `Quit_Action`
    - Create `lib/core/quit_action.dart`
    - Stop `Kevin_Service`, deactivate `Wake_Word_Detector`, dismiss persistent notification, call `SystemNavigator.pop()` / `exit(0)`
    - Wire to AppBar Quit button and notification "Quit" `PendingIntent`
    - _Requirements: 13.2, 13.3, 13.4, 13.5_

  - [~] 20.2 Write property test for Quit_Action terminates all components (Property 13)
    - **Property 13: Quit_Action Terminates All Kevin Components**
    - For any `Quit_Action` invocation, after completion: `Kevin_Service.isRunning == false`, `Wake_Word_Detector.isActive == false`, notification dismissed
    - **Validates: Requirements 13.3, 13.4**

  - [~] 20.3 Write unit tests for `Quit_Action`
    - Verify service stopped, detector deactivated, notification dismissed in all invocation paths
    - _Requirements: 13.2, 13.3, 13.4, 13.5_

- [x] 21. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 22. App settings screen
  - [x] 22.1 Implement `SettingsScreen`
    - ElevenLabs API key input field
    - AI API key input field
    - Wake word enable/disable toggle (starts/stops `Kevin_Service`)
    - Wake word sensitivity slider (0.0–1.0)
    - TTS voice ID input
    - All fields persist via `SettingsService`
    - SciFi_Theme styled
    - _Requirements: 12.2, 12.6_

  - [x] 22.2 Wire settings navigation from `AppBar` or main screen
    - _Requirements: 12.2_

- [x] 23. Full `ConversationScreen` integration — ElevenLabs flows
  - [x] 23.1 Wire TTS response flow
    - When `ResponseMode == Voice` and `AIIntent` is `generalQuery` or `osAction`, call `ElevenLabsClient.synthesizeSpeech`, pipe to `AudioPlayerService`, render `VoiceNoteBubble`
    - Fall back to text bubble on `TTSSynthesisError`
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [x] 23.2 Wire Music generation flow
    - When `AIIntent == elevenLabsMusic`, call `ElevenLabsClient.generateMusic`, play via `AudioPlayerService`, render `VoiceNoteBubble`
    - _Requirements: 15.2_

  - [x] 23.3 Wire SFX generation flow
    - When `AIIntent == elevenLabsSFX`, call `ElevenLabsClient.generateSoundEffect`, play via `AudioPlayerService`, render `VoiceNoteBubble`
    - _Requirements: 15.2_

  - [x] 23.4 Wire wake-word-triggered voice input to `ConversationScreen`
    - `Kevin_Service` emits `WakeWordEvent` → show `ListeningToast` + play activation tone + start mic capture → silence timeout → `ElevenLabsClient.transcribeRealtime` → `AI_Engine.process` → render response
    - _Requirements: 11.2, 11.3, 11.5, 11.6, 11.7, 11.9_

- [x] 24. Offline fallback and full error→UI mapping
  - [x] 24.1 Implement offline fallback behavior
    - When `OfflineException` is thrown, render red inline error bubble with "No internet connection" message
    - Allow OS actions and time/date queries to proceed offlineTest your knowledge!


    - _Requirements: 10.1_

  - [x] 24.2 Wire all error types to UI
    - Map every exception type to its specified UI response per the Error → UI Mapping table in the design
    - Ensure `TimeoutException` error bubble includes a Retry button that re-submits the last request
    - _Requirements: 10.1, 10.2, 4.5, 9.4, 6.5, 8.4, 8.5, 3.3, 4.6_

- [~] 25. Remaining property-based tests
  - [~] 25.1 Write property test for OS action result feedback (Property 5) — if not already covered in task 9.5
    - **Property 5: OS Action Result Always Produces User Feedback**
    - **Validates: Requirements 6.4, 6.5**

  - [~] 25.2 Write property test for response delivery mode (Property 2) — if not already covered in task 14.3
    - **Property 2: Response Delivery Mode Matches Active ResponseMode**
    - **Validates: Requirements 5.2, 5.3**

- [~] 26. Remaining unit and widget tests
  - [~] 26.1 Write unit tests for `AI_Engine` intent classification (all 5 intent types)
    - _Requirements: 6.1, 7.1_

  - [~] 26.2 Write unit tests for `OS_Bridge` settings mapping (all 6 `SettingsTarget` values, both platforms)
    - _Requirements: 6.2, 6.3_

  - [~] 26.3 Write widget tests for `ConversationView` empty and active states
    - _Requirements: 15.1, 15.5, 15.6_

  - [~] 26.4 Write widget test for `ResponseModeToggle` persistence across rebuilds
    - _Requirements: 5.4_

- [x] 27. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Property tests use the [`propcheck`](https://pub.dev/packages/propcheck) Dart library (minimum 100 iterations with shrinking)
- Tag each property test with: `// Feature: project-kevin, Property N: <property_text>`
- Checkpoints ensure incremental validation at logical milestones
- The design document is the authoritative source for all interface signatures, API endpoints, and data models
