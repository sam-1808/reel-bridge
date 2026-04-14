import '../../../core/db/app_database.dart';

class UserBookmark {
  const UserBookmark({
    required this.id,
    required this.userLocalId,
    required this.movieId,
    required this.movieTitle,
    this.posterUrl,
    this.releaseDate,
    this.plot,
  });

  factory UserBookmark.fromRow(Bookmark row) {
    return UserBookmark(
      id: row.id,
      userLocalId: row.userLocalId,
      movieId: row.movieId,
      movieTitle: row.movieTitle,
      posterUrl: row.posterUrl,
      releaseDate: row.releaseDate,
      plot: row.plot,
    );
  }

  final int id;
  final String userLocalId;
  final String movieId;
  final String movieTitle;
  final String? posterUrl;
  final String? releaseDate;
  final String? plot;
}
