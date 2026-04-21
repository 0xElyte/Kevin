// ignore_for_file: experimental_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'intent_router.dart';

/// Service that handles audio playback for TTS responses, Music, and SFX.
///
/// Pipes [Stream<Uint8List>] from ElevenLabs TTS into [just_audio]'s
/// [StreamAudioSource] for low-latency playback, and supports playing
/// pre-buffered MP3 bytes for Music and SFX.
class AudioPlayerService implements IAudioPlayerService {
  final AudioPlayer _player;

  /// Notifier for the current playing state.
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Stream controller for the current playback state.
  final _playbackStateController = StreamController<PlayerState>.broadcast();

  /// Stream of playback state changes.
  Stream<PlayerState> get playbackStateStream =>
      _playbackStateController.stream;

  /// Current playback state.
  PlayerState get playbackState => _player.playerState;

  /// Whether audio is currently playing.
  bool get isPlaying => _player.playing;

  AudioPlayerService({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    // Forward player state changes to our broadcast stream and update notifier
    _player.playerStateStream.listen((state) {
      _playbackStateController.add(state);
      isPlayingNotifier.value = state.playing;
    });
  }

  /// Plays audio from the given [audioStream].
  ///
  /// The stream should emit MP3 audio chunks from the ElevenLabs TTS API.
  /// This method pipes the stream into [just_audio]'s [StreamAudioSource]
  /// for low-latency playback.
  ///
  /// Returns a [Future] that completes when playback starts.
  ///
  /// Throws [PlayerException] if playback fails.
  @override
  Future<void> playStream(Stream<Uint8List> audioStream) async {
    try {
      // Stop any currently playing audio
      await stop();

      // Create a StreamAudioSource from the audio stream
      final audioSource = _TtsStreamAudioSource(audioStream);

      // Set the audio source and play
      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      throw PlayerException(0, 'Failed to play audio stream: $e', null);
    }
  }

  /// Plays audio from pre-buffered MP3 [bytes].
  ///
  /// Used for Music and SFX playback where the full audio is available
  /// before playback begins.
  ///
  /// Returns a [Future] that completes when playback starts.
  ///
  /// Throws [PlayerException] if playback fails.
  @override
  Future<void> playBytes(Uint8List mp3Bytes) async {
    try {
      await stop();
      final audioSource = _BytesAudioSource(mp3Bytes);
      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      throw PlayerException(0, 'Failed to play audio bytes: $e', null);
    }
  }

  /// Pauses the currently playing audio.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resumes playback if paused.
  Future<void> resume() async {
    await _player.play();
  }

  /// Stops playback and releases the current audio source.
  @override
  Future<void> stop() async {
    await _player.stop();
  }

  /// Disposes of the audio player and closes streams.
  Future<void> dispose() async {
    await _player.dispose();
    await _playbackStateController.close();
    isPlayingNotifier.dispose();
  }
}

/// Custom [StreamAudioSource] that reads from a [Stream<Uint8List>].
///
/// This allows piping TTS audio chunks directly into [just_audio] for
/// low-latency playback without buffering the entire response.
class _TtsStreamAudioSource extends StreamAudioSource {
  final Stream<Uint8List> _audioStream;
  final List<int> _buffer = [];
  StreamSubscription<Uint8List>? _subscription;
  bool _isDone = false;

  _TtsStreamAudioSource(this._audioStream);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // If this is a new request, start consuming the stream
    if (_subscription == null && !_isDone) {
      final completer = Completer<void>();

      _subscription = _audioStream.listen(
        (chunk) {
          _buffer.addAll(chunk);
          // Complete on first chunk to allow playback to start
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onDone: () {
          _isDone = true;
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        cancelOnError: true,
      );

      // Wait for at least the first chunk before returning
      await completer.future;
    }

    // Determine the range to return
    final actualStart = start ?? 0;
    final actualEnd = end ?? _buffer.length;

    // Wait for enough data if we don't have it yet
    while (!_isDone && _buffer.length < actualEnd) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    final rangeEnd = actualEnd.clamp(0, _buffer.length);
    final rangeStart = actualStart.clamp(0, rangeEnd);

    final bytes = Uint8List.fromList(_buffer.sublist(rangeStart, rangeEnd));

    return StreamAudioResponse(
      sourceLength: _isDone ? _buffer.length : null,
      contentLength: bytes.length,
      offset: rangeStart,
      stream: Stream.value(bytes),
      contentType: 'audio/mpeg',
    );
  }
}

/// Custom [StreamAudioSource] that serves pre-buffered MP3 [bytes].
///
/// Used for Music and SFX playback where the full audio is available upfront.
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final actualStart = start ?? 0;
    final actualEnd = end ?? _bytes.length;
    final rangeEnd = actualEnd.clamp(0, _bytes.length);
    final rangeStart = actualStart.clamp(0, rangeEnd);

    final slice = _bytes.sublist(rangeStart, rangeEnd);

    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: slice.length,
      offset: rangeStart,
      stream: Stream.value(slice),
      contentType: 'audio/mpeg',
    );
  }
}
