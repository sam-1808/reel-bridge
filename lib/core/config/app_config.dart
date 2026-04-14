import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.reqresBaseUrl,
    required this.reqresApiKey,
    required this.reqresEnvironment,
    required this.omdbBaseUrl,
    required this.omdbApiKey,
    required this.defaultMovieQuery,
    required this.failureRate,
  });

  factory AppConfig.fromEnvironment() {
    const reqresApiKey = String.fromEnvironment('REQRES_API_KEY');
    const reqresEnvironment = String.fromEnvironment(
      'REQRES_ENV',
      defaultValue: 'dev',
    );
    const omdbApiKey = String.fromEnvironment('OMDB_API_KEY');
    const defaultMovieQuery = String.fromEnvironment(
      'DEFAULT_MOVIE_QUERY',
      defaultValue: 'movie',
    );
    const failureRateRaw = String.fromEnvironment(
      'SIMULATED_GET_FAILURE_RATE',
      defaultValue: '0.3',
    );

    return AppConfig(
      reqresBaseUrl: const String.fromEnvironment(
        'REQRES_BASE_URL',
        defaultValue: 'https://reqres.in',
      ),
      reqresApiKey: reqresApiKey,
      reqresEnvironment: reqresEnvironment,
      omdbBaseUrl: const String.fromEnvironment(
        'OMDB_BASE_URL',
        defaultValue: 'https://www.omdbapi.com',
      ),
      omdbApiKey: omdbApiKey,
      defaultMovieQuery: defaultMovieQuery,
      failureRate: double.tryParse(failureRateRaw) ?? 0.3,
    );
  }

  final String reqresBaseUrl;
  final String reqresApiKey;
  final String reqresEnvironment;
  final String omdbBaseUrl;
  final String omdbApiKey;
  final String defaultMovieQuery;
  final double failureRate;

  bool get hasRequiredKeys =>
      reqresApiKey.trim().isNotEmpty && omdbApiKey.trim().isNotEmpty;

  List<String> get missingValues {
    final missing = <String>[];

    if (reqresApiKey.trim().isEmpty) {
      missing.add('REQRES_API_KEY');
    }
    if (omdbApiKey.trim().isEmpty) {
      missing.add('OMDB_API_KEY');
    }

    return missing;
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
