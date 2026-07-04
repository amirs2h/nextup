class ShowModel {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final String? originalLanguage;
  final double popularity;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final String? status;
  final List<SeasonModel>? seasons;

  ShowModel({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.voteAverage = 0,
    this.voteCount = 0,
    this.genreIds = const [],
    this.originalLanguage,
    this.popularity = 0,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.status,
    this.seasons,
  });

  factory ShowModel.fromJson(Map<String, dynamic> json) {
    return ShowModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate: json['first_air_date'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      originalLanguage: json['original_language'],
      popularity: (json['popularity'] ?? 0).toDouble(),
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
      status: json['status'],
      seasons: json['seasons'] != null
          ? (json['seasons'] as List).map((s) => SeasonModel.fromJson(s)).toList()
          : null,
    );
  }

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : null;
}

class SeasonModel {
  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? airDate;
  final int episodeCount;
  final List<EpisodeModel>? episodes;

  SeasonModel({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.episodeCount = 0,
    this.episodes,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      airDate: json['air_date'],
      episodeCount: json['episode_count'] ?? 0,
      episodes: json['episodes'] != null
          ? (json['episodes'] as List).map((e) => EpisodeModel.fromJson(e)).toList()
          : null,
    );
  }

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;
}

class EpisodeModel {
  final int id;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final int? runtime;
  final double voteAverage;

  EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtime,
    this.voteAverage = 0,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'],
      stillPath: json['still_path'],
      airDate: json['air_date'],
      runtime: json['runtime'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
    );
  }

  String? get stillUrl => stillPath != null
      ? 'https://image.tmdb.org/t/p/w500$stillPath'
      : null;
}
