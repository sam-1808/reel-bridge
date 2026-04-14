import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/movie_repository.dart';
import '../domain/movie.dart';

final movieDetailProvider = FutureProvider.family<MovieDetail, String>((
  ref,
  imdbId,
) {
  return ref.watch(movieRepositoryProvider).fetchMovieDetail(imdbId);
});
