class CommentModel {
  final String id;
  final String userId;
  final String? username;
  final String? userAvatar;
  final int tmdbId;
  final String mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final String content;
  final int likesCount;
  final bool isLikedByMe;
  final DateTime createdAt;
  final String? parentId;
  final String? title;
  final int replyCount;
  final bool isReply;

  CommentModel({
    required this.id,
    required this.userId,
    this.username,
    this.userAvatar,
    required this.tmdbId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    required this.content,
    this.likesCount = 0,
    this.isLikedByMe = false,
    required this.createdAt,
    this.parentId,
    this.title,
    this.replyCount = 0,
    this.isReply = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final parentId = json['parent_id'] as String?;
    return CommentModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['profiles']?['username'],
      userAvatar: json['profiles']?['avatar_url'],
      tmdbId: json['tmdb_id'] ?? 0,
      mediaType: json['media_type'] ?? '',
      seasonNumber: json['season_number'],
      episodeNumber: json['episode_number'],
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      isLikedByMe: json['is_liked_by_me'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      parentId: parentId,
      title: json['title'],
      replyCount: json['reply_count'] ?? 0,
      isReply: parentId != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'content': content,
      'title': title,
      'parent_id': parentId,
    };
  }
}
