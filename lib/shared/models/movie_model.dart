class MovieModel {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final String? originalLanguage;
  final double popularity;
  final int? runtime;
  final String? status;
  final int? budget;
  final int? revenue;

  MovieModel({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0,
    this.voteCount = 0,
    this.genreIds = const [],
    this.originalLanguage,
    this.popularity = 0,
    this.runtime,
    this.status,
    this.budget,
    this.revenue,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      originalLanguage: json['original_language'],
      popularity: (json['popularity'] ?? 0).toDouble(),
      runtime: json['runtime'],
      status: json['status'],
      budget: json['budget'],
      revenue: json['revenue'],
    );
  }

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : null;

  String get runtimeFormatted {
    if (runtime == null) return '';
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
