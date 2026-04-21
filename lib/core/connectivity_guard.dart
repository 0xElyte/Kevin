import 'package:connectivity_plus/connectivity_plus.dart';
import 'exceptions.dart';

/// Guards network requests by checking connectivity before executing them.
class ConnectivityGuard {
  final Connectivity _connectivity;

  ConnectivityGuard({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Executes [request] only if the device has network connectivity.
  ///
  /// Throws [OfflineException] if no connectivity is detected.
  Future<T> withConnectivity<T>(Future<T> Function() request) async {
    if (!await _isConnected()) {
      throw const OfflineException('No internet connection');
    }
    return request();
  }

  Future<bool> _isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Public connectivity check without any timeout wrapping.
  Future<bool> isConnected() => _isConnected();
}
