import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../bookmarks/data/bookmark_repository.dart';
import '../../bookmarks/providers/bookmark_providers.dart';
import '../../users/domain/app_user.dart';
import '../data/movie_repository.dart';
import '../domain/movie.dart';

class MovieListPage extends ConsumerStatefulWidget {
  const MovieListPage({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<MovieListPage> createState() => _MovieListPageState();
}

class _MovieListPageState extends ConsumerState<MovieListPage> {
  final _scrollController = ScrollController();
  late final TextEditingController _queryController;

  List<MovieSummary> _movies = const [];
  String _activeQuery = '';
  int _page = 1;
  int _totalResults = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  bool get _hasMore => _page * 10 < _totalResults;

  @override
  void initState() {
    super.initState();
    final defaultQuery = ref.read(appConfigProvider).defaultMovieQuery;
    _queryController = TextEditingController(text: defaultQuery);
    _scrollController.addListener(_onScroll);
    _loadInitial(defaultQuery);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitial(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _movies = const [];
      _activeQuery = query;
      _page = 1;
      _totalResults = 0;
    });

    try {
      final result = await ref
          .read(movieRepositoryProvider)
          .searchMovies(query: query, page: 1);
      if (!mounted) {
        return;
      }

      setState(() {
        _movies = result.items;
        _page = result.page;
        _totalResults = result.totalResults;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '$error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await ref
          .read(movieRepositoryProvider)
          .searchMovies(query: _activeQuery, page: _page + 1);
      if (!mounted) {
        return;
      }

      final existingIds = _movies.map((movie) => movie.imdbId).toSet();
      final nextItems = [
        ..._movies,
        ...result.items.where((movie) => !existingIds.contains(movie.imdbId)),
      ];

      setState(() {
        _movies = nextItems;
        _page = result.page;
        _totalResults = result.totalResults;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _toggleBookmark({
    required MovieSummary movie,
    required bool isBookmarked,
  }) async {
    await ref
        .read(bookmarkRepositoryProvider)
        .toggleBookmark(
          user: widget.user,
          movie: movie,
          isCurrentlyBookmarked: isBookmarked,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkedIds =
        ref.watch(bookmarkedMovieIdsProvider(widget.user.localId)).value ??
        const <String>{};

    return Scaffold(
      appBar: AppBar(title: Text(widget.user.name)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Movie list',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.user.isPendingSync
                        ? 'This user was created offline and can already bookmark movies.'
                        : 'Bookmarks stay tied to this user as you browse.',
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(AppRouter.userBookmarks(widget.user)),
                      icon: const Icon(Icons.bookmarks_outlined),
                      label: const Text('View bookmarks'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search OMDB movies',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: _loadInitial,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => _loadInitial(_queryController.text),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(bookmarkedIds)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Set<String> bookmarkedIds) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load movies.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadInitial(_queryController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No movies matched that search yet.'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInitial(_activeQuery),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: _movies.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _movies.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final movie = _movies[index];
          final isBookmarked = bookmarkedIds.contains(movie.imdbId);

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.of(
                context,
              ).push(AppRouter.movieDetail(user: widget.user, movie: movie)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PosterThumbnail(url: movie.posterUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text('${movie.year} • ${movie.type.toUpperCase()}'),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () => _toggleBookmark(
                              movie: movie,
                              isBookmarked: isBookmarked,
                            ),
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_outlined,
                            ),
                            label: Text(
                              isBookmarked ? 'Bookmarked' : 'Bookmark',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PosterThumbnail extends StatelessWidget {
  const _PosterThumbnail({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 88,
        height: 128,
        color: const Color(0xFFE2E8F0),
        child: url == null
            ? const Icon(Icons.movie_creation_outlined, size: 36)
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined, size: 36),
              ),
      ),
    );
  }
}
