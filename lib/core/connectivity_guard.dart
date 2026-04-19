import 'package:connectivity_plus/connectivity_plus.dart';
import 'exceptions.dart';

/// Guards network requests by checking connectivity and enforcing a 10-second timeout.
class ConnectivityGuard {
  final Connectivity _connectivity;

  ConnectivityGuard({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Executes [request] only if the device has network connectivity.
  ///
  /// Throws [OfflineException] if no connectivity is detected.
  /// Throws [TimeoutException] if the request exceeds 10 seconds.
  Future<T> withConnectivity<T>(Future<T> Function() request) async {
    if (!await _isConnected()) {
      throw const OfflineException('No internet connection');
    }
    return request().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw const TimeoutException('Request timed out'),
    );
  }

  Future<bool> _isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
