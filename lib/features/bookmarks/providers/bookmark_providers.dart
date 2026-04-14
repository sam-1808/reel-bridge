import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bookmark_repository.dart';
import '../domain/user_bookmark.dart';

final bookmarkedMovieIdsProvider = StreamProvider.family<Set<String>, String>((
  ref,
  userLocalId,
) {
  return ref
      .watch(bookmarkRepositoryProvider)
      .watchBookmarkedMovieIds(userLocalId);
});

final userBookmarksProvider = StreamProvider.family<List<UserBookmark>, String>(
  (ref, userLocalId) {
    return ref.watch(bookmarkRepositoryProvider).watchBookmarks(userLocalId);
  },
);
