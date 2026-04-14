import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../movies/domain/movie.dart';
import '../../users/domain/app_user.dart';
import '../domain/user_bookmark.dart';

class BookmarkRepository {
  BookmarkRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Stream<Set<String>> watchBookmarkedMovieIds(String userLocalId) {
    return _database
        .watchBookmarksForUser(userLocalId)
        .map((rows) => rows.map((row) => row.movieId).toSet());
  }

  Stream<List<UserBookmark>> watchBookmarks(String userLocalId) {
    return _database
        .watchBookmarksForUser(userLocalId)
        .map((rows) => rows.map(UserBookmark.fromRow).toList());
  }

  Future<void> addBookmark({
    required AppUser user,
    required MovieSummary movie,
    String? plot,
  }) {
    final now = DateTime.now();
    return _database.upsertBookmark(
      BookmarksCompanion.insert(
        userLocalId: user.localId,
        userRemoteId: Value(user.remoteId),
        movieId: movie.imdbId,
        movieTitle: movie.title,
        posterUrl: Value(movie.posterUrl),
        releaseDate: Value(movie.year),
        plot: Value(plot),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> removeBookmark({
    required AppUser user,
    required String movieId,
  }) {
    return _database.removeBookmark(
      userLocalIdValue: user.localId,
      movieIdValue: movieId,
    );
  }

  Future<void> toggleBookmark({
    required AppUser user,
    required MovieSummary movie,
    required bool isCurrentlyBookmarked,
    String? plot,
  }) async {
    if (isCurrentlyBookmarked) {
      await removeBookmark(user: user, movieId: movie.imdbId);
      return;
    }

    await addBookmark(user: user, movie: movie, plot: plot);
  }
}

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(database: ref.watch(appDatabaseProvider));
});
