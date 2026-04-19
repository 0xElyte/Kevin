class WakeWordEvent {
  final DateTime detectedAt;
  final double confidence;

  const WakeWordEvent({required this.detectedAt, required this.confidence});
}
