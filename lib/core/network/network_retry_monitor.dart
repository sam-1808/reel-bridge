import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkRetryMonitor extends Notifier<int> {
  @override
  int build() => 0;

  void beginRetry() {
    state = state + 1;
  }

  void endRetry() {
    if (state > 0) {
      state = state - 1;
    }
  }
}

final networkRetryMonitorProvider = NotifierProvider<NetworkRetryMonitor, int>(
  NetworkRetryMonitor.new,
);

final isRetryingNetworkProvider = Provider<bool>((ref) {
  return ref.watch(networkRetryMonitorProvider) > 0;
});
