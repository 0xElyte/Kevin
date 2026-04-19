import 'dart:async';

/// A wrapper for async operations that can be cancelled.
class CancelableOperation {
  final Completer<void> _completer = Completer<void>();
  bool _isCancelled = false;

  /// Whether this operation has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Future that completes when the operation is cancelled.
  Future<void> get onCancel => _completer.future;

  /// Cancels this operation.
  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  /// Throws [OperationCancelledException] if this operation has been cancelled.
  void checkCancelled() {
    if (_isCancelled) {
      throw OperationCancelledException();
    }
  }
}

/// Exception thrown when an operation is cancelled.
class OperationCancelledException implements Exception {
  @override
  String toString() => 'Operation was cancelled';
}
