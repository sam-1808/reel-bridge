import 'package:flutter/material.dart';

import '../features/bookmarks/presentation/user_bookmarks_page.dart';
import '../features/movies/domain/movie.dart';
import '../features/movies/presentation/movie_detail_page.dart';
import '../features/movies/presentation/movie_list_page.dart';
import '../features/users/domain/app_user.dart';
import '../features/users/presentation/add_user_page.dart';

abstract final class AppRouter {
  static Route<void> addUser() {
    return MaterialPageRoute<void>(builder: (_) => const AddUserPage());
  }

  static Route<void> movieList(AppUser user) {
    return MaterialPageRoute<void>(builder: (_) => MovieListPage(user: user));
  }

  static Route<void> movieDetail({
    required AppUser user,
    required MovieSummary movie,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => MovieDetailPage(user: user, movie: movie),
    );
  }

  static Route<void> userBookmarks(AppUser user) {
    return MaterialPageRoute<void>(
      builder: (_) => UserBookmarksPage(user: user),
    );
  }
}
