import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Stream<bool> watchOnlineStatus() async* {
    yield await isOnline();
    yield* _connectivity.onConnectivityChanged.map(_resultsToOnline).distinct();
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _resultsToOnline(results);
  }

  bool _resultsToOnline(List<ConnectivityResult> results) {
    return !results.contains(ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).watchOnlineStatus();
});
