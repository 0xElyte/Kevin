import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_kevin/core/connectivity_guard.dart';
import 'package:project_kevin/core/exceptions.dart' as app_exceptions;

/// Creates a [ConnectivityGuard] whose connectivity check is overridden
/// by injecting a fake [Connectivity]-like check via a wrapper.
///
/// Since [Connectivity] cannot be subclassed, we test via the public API
/// by injecting a [Connectivity] instance whose [checkConnectivity] is
/// overridden through a thin wrapper class.
class _FakeConnectivity implements Connectivity {
  final List<ConnectivityResult> _results;

  _FakeConnectivity(this._results);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;

  // Unused members — only checkConnectivity is exercised by ConnectivityGuard.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ConnectivityGuard', () {
    test('throws OfflineException when device is offline', () async {
      final guard = ConnectivityGuard(
        connectivity: _FakeConnectivity([ConnectivityResult.none]),
      );

      await expectLater(
        guard.withConnectivity(() async => 'result'),
        throwsA(isA<app_exceptions.OfflineException>()),
      );
    });

    test(
      'throws TimeoutException when request exceeds 10 seconds',
      () async {
        final guard = ConnectivityGuard(
          connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        );

        await expectLater(
          guard.withConnectivity(() async {
            await Future.delayed(const Duration(seconds: 11));
            return 'result';
          }),
          throwsA(isA<app_exceptions.TimeoutException>()),
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'returns value when connected and request completes in time',
      () async {
        final guard = ConnectivityGuard(
          connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        );

        final result = await guard.withConnectivity(() async => 42);

        expect(result, equals(42));
      },
    );

    test('returns value when connected via mobile data', () async {
      final guard = ConnectivityGuard(
        connectivity: _FakeConnectivity([ConnectivityResult.mobile]),
      );

      final result = await guard.withConnectivity(() async => 'ok');

      expect(result, equals('ok'));
    });

    test('throws OfflineException when all results are none', () async {
      final guard = ConnectivityGuard(
        connectivity: _FakeConnectivity([
          ConnectivityResult.none,
          ConnectivityResult.none,
        ]),
      );

      await expectLater(
        guard.withConnectivity(() async => 'result'),
        throwsA(isA<app_exceptions.OfflineException>()),
      );
    });

    test('succeeds when at least one result is not none', () async {
      final guard = ConnectivityGuard(
        connectivity: _FakeConnectivity([
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
      );

      final result = await guard.withConnectivity(() async => 'connected');

      expect(result, equals('connected'));
    });
  });
}
