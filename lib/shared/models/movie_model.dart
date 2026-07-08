import '../../core/config/app_config.dart';

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
  final String? tagline;
  final List<Map<String, dynamic>>? genres;
  final List<Map<String, dynamic>>? productionCompanies;
  final List<Map<String, dynamic>>? spokenLanguages;
  final String? imdbId;
  final String? homepage;

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
    this.tagline,
    this.genres,
    this.productionCompanies,
    this.spokenLanguages,
    this.imdbId,
    this.homepage,
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
      tagline: json['tagline'],
      genres: json['genres'] != null ? List<Map<String, dynamic>>.from(json['genres']) : null,
      productionCompanies: json['production_companies'] != null ? List<Map<String, dynamic>>.from(json['production_companies']) : null,
      spokenLanguages: json['spoken_languages'] != null ? List<Map<String, dynamic>>.from(json['spoken_languages']) : null,
      imdbId: json['imdb_id'],
      homepage: json['homepage'],
    );
  }

  String? get posterUrl => posterPath != null
      ? AppConfig.getImageUrl(posterPath, size: 'w500')
      : null;

  String? get backdropUrl => backdropPath != null
      ? AppConfig.getImageUrl(backdropPath, size: 'original')
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

  String get budgetFormatted {
    if (budget == null || budget == 0) return 'N/A';
    if (budget! >= 1000000) return '\$${(budget! / 1000000).toStringAsFixed(0)}M';
    if (budget! >= 1000) return '\$${(budget! / 1000).toStringAsFixed(0)}K';
    return '\$$budget';
  }

  String get revenueFormatted {
    if (revenue == null || revenue == 0) return 'N/A';
    if (revenue! >= 1000000) return '\$${(revenue! / 1000000).toStringAsFixed(0)}M';
    if (revenue! >= 1000) return '\$${(revenue! / 1000).toStringAsFixed(0)}K';
    return '\$$revenue';
  }
}
