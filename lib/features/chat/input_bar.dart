import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/exceptions.dart';
import '../../core/input_validator.dart';
import '../../theme/scifi_theme.dart';

/// The input bar at the bottom of the conversation screen.
///
/// Layout: [📎] [TextField (2000-char limit)] [🎤] [➤]
///
/// - [AttachButton] opens the native file picker, validates the selected file,
///   and displays the filename inline.
/// - [TextField] enforces a 2000-character limit with an inline counter.
///   When the limit is exceeded the counter turns red and [SendButton] is
///   disabled.
/// - [VoiceButton] triggers mic capture via [onVoicePressed]; shows a
///   recording indicator when [isRecording] is true.
/// - [SendButton] is disabled when the text field is empty or the character
///   limit is exceeded.
class InputBar extends StatefulWidget {
  /// Optional external controller. If null, [InputBar] creates its own.
  final TextEditingController? controller;

  /// Called when the user taps Send.
  final void Function(String text, {String? attachmentPath}) onSend;

  /// Called when the user taps the voice button.
  final void Function() onVoicePressed;

  /// Called when the user taps the stop button during processing.
  final void Function() onCancelProcessing;

  /// Whether the voice button should show a recording indicator.
  final bool isRecording;

  /// Whether Kevin is currently processing a request.
  final bool isProcessing;

  const InputBar({
    super.key,
    this.controller,
    required this.onSend,
    required this.onVoicePressed,
    required this.onCancelProcessing,
    this.isRecording = false,
    this.isProcessing = false,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  String? _attachmentPath;
  String? _attachmentName;
  String? _attachmentError;

  static const int _maxLength = 2000;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Rebuild to update counter colour and button state.
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  bool get _isOverLimit => _controller.text.length > _maxLength;
  bool get _isEmpty => _controller.text.isEmpty;
  bool get _canSend => !_isEmpty && !_isOverLimit && !widget.isProcessing;

  Future<void> _pickFile() async {
    setState(() {
      _attachmentError = null;
    });

    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    final name = file.name;
    final size = file.size;
    final mimeType = _mimeTypeFromExtension(name);

    try {
      validateFileAttachment(mimeType, size);
      setState(() {
        _attachmentPath = path;
        _attachmentName = name;
        _attachmentError = null;
      });
    } on FileTooLargeError catch (e) {
      setState(() {
        _attachmentPath = null;
        _attachmentName = null;
        _attachmentError = e.message;
      });
    } on UnsupportedFileTypeError catch (e) {
      setState(() {
        _attachmentPath = null;
        _attachmentName = null;
        _attachmentError = e.message;
      });
    }
  }

  void _clearAttachment() {
    setState(() {
      _attachmentPath = null;
      _attachmentName = null;
      _attachmentError = null;
    });
  }

  void _send() {
    if (!_canSend) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text, attachmentPath: _attachmentPath);
    _controller.clear();
    _clearAttachment();
  }

  /// Derives a MIME type from the file extension for validation purposes.
  String _mimeTypeFromExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/$ext';
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _controller.text.length;
    final counterColor = _isOverLimit
        ? SciFiTheme.colorAccent
        : SciFiTheme.colorTextSecondary;

    return Container(
      color: SciFiTheme.colorSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attachment chip / error row
          if (_attachmentName != null) _buildAttachmentChip(),
          if (_attachmentError != null) _buildAttachmentError(),

          // Main input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Attach button
              _AttachButton(onPressed: _pickFile),

              const SizedBox(width: 6),

              // Text field + counter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _controller,
                      enabled:
                          !widget.isProcessing, // Disable during processing
                      maxLines: 4,
                      minLines: 1,
                      style: GoogleFonts.exo2(
                        color: SciFiTheme.colorTextPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type or Speak to Kevin...',
                        hintStyle: GoogleFonts.exo2(
                          color: SciFiTheme.colorTextSecondary,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: SciFiTheme.colorBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            SciFiTheme.borderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: SciFiTheme.colorAccentDim,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            SciFiTheme.borderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: SciFiTheme.colorAccentDim,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            SciFiTheme.borderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: SciFiTheme.colorAccent,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            SciFiTheme.borderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: SciFiTheme.colorAccent,
                          ),
                        ),
                        // Show red border when over limit
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            SciFiTheme.borderRadius,
                          ),
                          borderSide: const BorderSide(
                            color: SciFiTheme.colorAccent,
                            width: 2,
                          ),
                        ),
                        errorText: _isOverLimit
                            ? 'Message exceeds $_maxLength characters'
                            : null,
                        errorStyle: GoogleFonts.exo2(
                          color: SciFiTheme.colorAccent,
                          fontSize: 11,
                        ),
                        suffix: Text(
                          '$charCount / $_maxLength',
                          style: GoogleFonts.exo2(
                            color: counterColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Voice button or Stop button (during processing)
              widget.isProcessing
                  ? _StopButton(onPressed: widget.onCancelProcessing)
                  : _VoiceButton(
                      isRecording: widget.isRecording,
                      onPressed: widget.onVoicePressed,
                    ),

              const SizedBox(width: 4),

              // Send button (hidden during processing)
              if (!widget.isProcessing)
                _SendButton(enabled: _canSend, onPressed: _send),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentChip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 40),
      child: Chip(
        backgroundColor: SciFiTheme.colorSurface,
        side: const BorderSide(color: SciFiTheme.colorAccentDim),
        label: Text(
          _attachmentName!,
          style: GoogleFonts.exo2(
            color: SciFiTheme.colorTextPrimary,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
          color: SciFiTheme.colorTextSecondary,
        ),
        onDeleted: _clearAttachment,
      ),
    );
  }

  Widget _buildAttachmentError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 40),
      child: Text(
        _attachmentError!,
        style: GoogleFonts.exo2(color: SciFiTheme.colorAccent, fontSize: 11),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _AttachButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AttachButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.attach_file),
      color: SciFiTheme.colorAccent,
      tooltip: 'Attach file',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const _VoiceButton({required this.isRecording, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(isRecording ? Icons.stop_circle : Icons.mic),
      color: isRecording ? SciFiTheme.colorAccent : SciFiTheme.colorAccent,
      tooltip: isRecording ? 'Stop recording' : 'Voice input',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SendButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.send),
      color: enabled ? SciFiTheme.colorAccent : SciFiTheme.colorTextSecondary,
      tooltip: 'Send',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StopButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.stop_circle),
      color: SciFiTheme.colorAccent,
      tooltip: 'Cancel processing',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
