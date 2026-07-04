class WatchHistoryModel {
  final String id;
  final String userId;
  final int tmdbId;
  final String mediaType; // 'tv' or 'movie'
  final int? seasonNumber;
  final int? episodeNumber;
  final DateTime watchedAt;

  WatchHistoryModel({
    required this.id,
    required this.userId,
    required this.tmdbId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    required this.watchedAt,
  });

  factory WatchHistoryModel.fromJson(Map<String, dynamic> json) {
    return WatchHistoryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      tmdbId: json['tmdb_id'] ?? 0,
      mediaType: json['media_type'] ?? '',
      seasonNumber: json['season_number'],
      episodeNumber: json['episode_number'],
      watchedAt: DateTime.parse(json['watched_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'watched_at': watchedAt.toIso8601String(),
    };
  }

  bool get isEpisode => seasonNumber != null && episodeNumber != null;
}
