import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import 'network_retry_monitor.dart';

class NetworkResilienceInterceptor extends Interceptor {
  NetworkResilienceInterceptor({
    required Dio rawDio,
    required NetworkRetryMonitor retryMonitor,
    required double failureRate,
  }) : _rawDio = rawDio,
       _retryMonitor = retryMonitor,
       _failureRate = failureRate.clamp(0, 1),
       _random = Random();

  final Dio _rawDio;
  final NetworkRetryMonitor _retryMonitor;
  final double _failureRate;
  final Random _random;

  static const _skipKey = 'skip_resilience';
  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final shouldHandle =
        options.method.toUpperCase() == 'GET' &&
        options.extra[_skipKey] != true;

    if (!shouldHandle) {
      handler.next(options);
      return;
    }

    try {
      final response = await _executeWithRetry(options);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  Future<Response<dynamic>> _executeWithRetry(RequestOptions original) async {
    var attempt = (original.extra[_attemptKey] as int?) ?? 0;

    while (true) {
      final request = original.copyWith(
        extra: {...original.extra, _skipKey: true, _attemptKey: attempt},
      );

      try {
        _maybeThrowSimulatedFailure(request);

        final response = await _rawDio.fetch<dynamic>(request);
        if (_isRetryableStatus(response.statusCode)) {
          throw DioException.badResponse(
            statusCode: response.statusCode ?? 500,
            requestOptions: request,
            response: response,
          );
        }
        return response;
      } on DioException catch (error) {
        if (!_shouldRetry(error) || request.cancelToken?.isCancelled == true) {
          rethrow;
        }

        attempt += 1;
        final delay = _backoffFor(attempt);
        _retryMonitor.beginRetry();
        try {
          await Future<void>.delayed(delay);
        } finally {
          _retryMonitor.endRetry();
        }
      }
    }
  }

  void _maybeThrowSimulatedFailure(RequestOptions request) {
    if (_random.nextDouble() > _failureRate) {
      return;
    }

    if (_random.nextBool()) {
      throw DioException.connectionError(
        requestOptions: request,
        reason: 'Simulated SocketException',
        error: const SocketException('Simulated offline error'),
      );
    }

    final response = Response<dynamic>(
      requestOptions: request,
      statusCode: 500,
      data: const {'error': 'Simulated internal server error'},
    );

    throw DioException.badResponse(
      statusCode: 500,
      requestOptions: request,
      response: response,
    );
  }

  bool _isRetryableStatus(int? statusCode) {
    return statusCode != null && statusCode >= 500;
  }

  bool _shouldRetry(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError => true,
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.badResponse => _isRetryableStatus(
        error.response?.statusCode,
      ),
      _ => false,
    };
  }

  Duration _backoffFor(int attempt) {
    final seconds = min(pow(2, min(attempt, 4)).toInt(), 12);
    return Duration(seconds: seconds);
  }
}
