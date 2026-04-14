import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/data/bookmark_repository.dart';
import '../../bookmarks/providers/bookmark_providers.dart';
import '../../users/domain/app_user.dart';
import '../domain/movie.dart';
import '../providers/movie_providers.dart';

class MovieDetailPage extends ConsumerWidget {
  const MovieDetailPage({super.key, required this.user, required this.movie});

  final AppUser user;
  final MovieSummary movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(movieDetailProvider(movie.imdbId));
    final bookmarkedIds =
        ref.watch(bookmarkedMovieIdsProvider(user.localId)).value ??
        const <String>{};
    final isBookmarked = bookmarkedIds.contains(movie.imdbId);

    return Scaffold(
      appBar: AppBar(title: const Text('Movie detail')),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load this movie.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          data: (detail) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: detail.posterUrl == null
                          ? Container(
                              color: const Color(0xFFD7E3E5),
                              child: const Icon(
                                Icons.movie_filter_outlined,
                                size: 72,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: detail.posterUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 72,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    detail.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoPill(label: detail.year),
                      _InfoPill(label: detail.released),
                      _InfoPill(label: detail.runtime),
                      _InfoPill(label: 'IMDb ${detail.imdbRating}'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => ref
                          .read(bookmarkRepositoryProvider)
                          .toggleBookmark(
                            user: user,
                            movie: movie,
                            isCurrentlyBookmarked: isBookmarked,
                            plot: detail.plot,
                          ),
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_add_outlined,
                      ),
                      label: Text(
                        isBookmarked
                            ? 'Remove bookmark'
                            : 'Bookmark this movie',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail.plot,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _DetailGrid(detail: detail),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _Row(label: 'Genre', value: detail.genre),
            const Divider(height: 24),
            _Row(label: 'Rated', value: detail.rated),
            const Divider(height: 24),
            _Row(label: 'Director', value: detail.director),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
