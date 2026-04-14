import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/movie.dart';

class MovieRepository {
  MovieRepository({required Dio omdbDio, required AppConfig config})
    : _omdbDio = omdbDio,
      _config = config;

  final Dio _omdbDio;
  final AppConfig _config;

  Future<MovieSearchPage> searchMovies({
    required String query,
    required int page,
  }) async {
    final normalizedQuery = query.trim().isEmpty
        ? _config.defaultMovieQuery
        : query.trim();
    final response = await _omdbDio.get<Map<String, dynamic>>(
      '/',
      queryParameters: {
        'apikey': _config.omdbApiKey,
        's': normalizedQuery,
        'page': page,
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    if ((data['Response'] as String?) == 'False') {
      return MovieSearchPage(items: const [], page: page, totalResults: 0);
    }

    final items = (data['Search'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => MovieSummary(
            imdbId: json['imdbID'] as String? ?? '',
            title: json['Title'] as String? ?? 'Untitled',
            year: json['Year'] as String? ?? 'Unknown',
            type: json['Type'] as String? ?? 'movie',
            posterUrl: _posterOrNull(json['Poster'] as String?),
          ),
        )
        .where((movie) => movie.imdbId.isNotEmpty)
        .toList();

    return MovieSearchPage(
      items: items,
      page: page,
      totalResults:
          int.tryParse('${data['totalResults'] ?? 0}') ?? items.length,
    );
  }

  Future<MovieDetail> fetchMovieDetail(String imdbId) async {
    final response = await _omdbDio.get<Map<String, dynamic>>(
      '/',
      queryParameters: {
        'apikey': _config.omdbApiKey,
        'i': imdbId,
        'plot': 'full',
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    if ((data['Response'] as String?) == 'False') {
      throw Exception(data['Error'] ?? 'Movie not found');
    }

    return MovieDetail(
      imdbId: data['imdbID'] as String? ?? imdbId,
      title: data['Title'] as String? ?? 'Untitled',
      year: data['Year'] as String? ?? 'Unknown',
      plot: data['Plot'] as String? ?? 'No description available.',
      genre: data['Genre'] as String? ?? 'Unknown',
      released: data['Released'] as String? ?? 'Unknown',
      rated: data['Rated'] as String? ?? 'N/A',
      runtime: data['Runtime'] as String? ?? 'N/A',
      director: data['Director'] as String? ?? 'Unknown',
      imdbRating: data['imdbRating'] as String? ?? 'N/A',
      posterUrl: _posterOrNull(data['Poster'] as String?),
    );
  }

  String? _posterOrNull(String? value) {
    if (value == null || value.trim().isEmpty || value == 'N/A') {
      return null;
    }
    return value;
  }
}

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository(
    omdbDio: ref.watch(omdbDioProvider),
    config: ref.watch(appConfigProvider),
  );
});
