class MovieSummary {
  const MovieSummary({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.type,
    this.posterUrl,
  });

  final String imdbId;
  final String title;
  final String year;
  final String type;
  final String? posterUrl;
}

class MovieDetail {
  const MovieDetail({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.plot,
    required this.genre,
    required this.released,
    required this.rated,
    required this.runtime,
    required this.director,
    required this.imdbRating,
    this.posterUrl,
  });

  final String imdbId;
  final String title;
  final String year;
  final String plot;
  final String genre;
  final String released;
  final String rated;
  final String runtime;
  final String director;
  final String imdbRating;
  final String? posterUrl;
}

class MovieSearchPage {
  const MovieSearchPage({
    required this.items,
    required this.page,
    required this.totalResults,
  });

  final List<MovieSummary> items;
  final int page;
  final int totalResults;

  bool get hasMore => page * 10 < totalResults;
}
