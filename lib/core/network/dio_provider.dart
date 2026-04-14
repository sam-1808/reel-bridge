import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'network_resilience_interceptor.dart';
import 'network_retry_monitor.dart';

final reqresDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final retryMonitor = ref.read(networkRetryMonitorProvider.notifier);
  final options = BaseOptions(
    baseUrl: config.reqresBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'x-api-key': config.reqresApiKey,
      'X-Reqres-Env': config.reqresEnvironment,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  final rawDio = Dio(options);
  final dio = Dio(options)
    ..interceptors.add(
      NetworkResilienceInterceptor(
        rawDio: rawDio,
        retryMonitor: retryMonitor,
        failureRate: config.failureRate,
      ),
    );

  ref.onDispose(() {
    dio.close(force: true);
    rawDio.close(force: true);
  });

  return dio;
});

final omdbDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final retryMonitor = ref.read(networkRetryMonitorProvider.notifier);
  final options = BaseOptions(
    baseUrl: config.omdbBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  );

  final rawDio = Dio(options);
  final dio = Dio(options)
    ..interceptors.add(
      NetworkResilienceInterceptor(
        rawDio: rawDio,
        retryMonitor: retryMonitor,
        failureRate: config.failureRate,
      ),
    );

  ref.onDispose(() {
    dio.close(force: true);
    rawDio.close(force: true);
  });

  return dio;
});
