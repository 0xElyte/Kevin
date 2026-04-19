import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';

import '../../services/audio_player_service.dart';
import '../../services/intent_router.dart';
import '../../theme/scifi_theme.dart';

/// Full-duplex live voice conversation screen with an ElevenLabs Agent.
///
/// - Streams mic audio to the agent via WebSocket.
/// - Plays agent audio responses in real time.
/// - Shows a pulsing orb to indicate agent speaking vs. user speaking.
class AgentSessionScreen extends StatefulWidget {
  final AgentSession session;
  final AudioPlayerService audioPlayerService;

  const AgentSessionScreen({
    super.key,
    required this.session,
    required this.audioPlayerService,
  });

  @override
  State<AgentSessionScreen> createState() => _AgentSessionScreenState();
}

class _AgentSessionScreenState extends State<AgentSessionScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioOutputSub;
  StreamSubscription<RecordState>? _recorderStateSub;

  bool _isAgentSpeaking = false;
  bool _isUserSpeaking = false;
  bool _sessionEnded = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listenToAgentAudio();
    _startMicStreaming();
  }

  void _listenToAgentAudio() {
    _audioOutputSub = widget.session.audioOutput.listen(
      (Uint8List chunk) async {
        if (!mounted) return;
        setState(() => _isAgentSpeaking = true);
        await widget.audioPlayerService.playBytes(chunk);
        if (mounted) setState(() => _isAgentSpeaking = false);
      },
      onDone: () {
        if (mounted) setState(() => _sessionEnded = true);
      },
      onError: (_) {
        if (mounted) setState(() => _sessionEnded = true);
      },
    );
  }

  Future<void> _startMicStreaming() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _recorderStateSub = _recorder.onStateChanged().listen((state) {
      if (mounted) {
        setState(() => _isUserSpeaking = state == RecordState.record);
      }
    });

    stream.listen((chunk) {
      widget.session.sendAudio(Uint8List.fromList(chunk));
    });
  }

  Future<void> _endSession() async {
    await _recorder.stop();
    await widget.session.close();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _audioOutputSub?.cancel();
    _recorderStateSub?.cancel();
    _recorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SciFiTheme.colorBackground,
      appBar: AppBar(
        backgroundColor: SciFiTheme.colorBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: SciFiTheme.colorAccent),
          onPressed: _endSession,
        ),
        title: Text(
          'KEVIN AGENT',
          style: GoogleFonts.orbitron(
            color: SciFiTheme.colorAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing orb
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: (_isAgentSpeaking || _isUserSpeaking)
                      ? _pulseAnimation.value
                      : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _isAgentSpeaking
                          ? SciFiTheme.colorAccent
                          : _isUserSpeaking
                          ? SciFiTheme.colorAccentDim
                          : SciFiTheme.colorSurface,
                      SciFiTheme.colorBackground,
                    ],
                  ),
                  border: Border.all(color: SciFiTheme.colorAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: SciFiTheme.colorAccent.withAlpha(80),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _isAgentSpeaking
                      ? Icons.volume_up
                      : _isUserSpeaking
                      ? Icons.mic
                      : Icons.graphic_eq,
                  color: SciFiTheme.colorTextPrimary,
                  size: 48,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              _sessionEnded
                  ? 'Session ended'
                  : _isAgentSpeaking
                  ? 'Kevin is speaking...'
                  : _isUserSpeaking
                  ? 'Listening...'
                  : 'Connected — speak to Kevin',
              style: GoogleFonts.exo2(
                color: SciFiTheme.colorTextPrimary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            if (widget.session.conversationId.isNotEmpty)
              Text(
                'ID: ${widget.session.conversationId}',
                style: GoogleFonts.exo2(
                  color: SciFiTheme.colorTextSecondary,
                  fontSize: 11,
                ),
              ),

            const SizedBox(height: 48),

            // End call button
            GestureDetector(
              onTap: _endSession,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade800,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(100),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'End Session',
              style: GoogleFonts.exo2(
                color: SciFiTheme.colorTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
