import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/spoiler_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/mixins/toggle_lock_mixin.dart';

class EpisodeDetailPage extends StatefulWidget {
  final int showId;
  final int seasonNumber;
  final int episodeNumber;

  const EpisodeDetailPage({
    super.key,
    required this.showId,
    required this.seasonNumber,
    required this.episodeNumber,
  });

  @override
  State<EpisodeDetailPage> createState() => _EpisodeDetailPageState();
}

class _EpisodeDetailPageState extends State<EpisodeDetailPage> with ToggleLockMixin {
  Map<String, dynamic>? _episodeData;
  String? _showName;
  String? _showPosterPath;
  bool _isLoading = true;
  bool _isWatched = false;
  double? _userRating;
  Map<String, int> _reactions = {};
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadEpisodeData();
  }

  Future<void> _loadEpisodeData() async {
    setState(() => _isLoading = true);
    try {
      final tmdb = context.read<TmdbService>();
      final supabase = context.read<SupabaseService>();
      final user = supabase.currentUser;

      final showDetails = await tmdb.getShowDetails(widget.showId);
      _showName = showDetails['name'] as String?;
      _showPosterPath = showDetails['poster_path'] as String?;

      final seasonData = await tmdb.getShowSeasonDetails(widget.showId, widget.seasonNumber);
      final episodes = seasonData['episodes'] as List? ?? [];
      final episode = episodes.firstWhere(
        (e) => (e['episode_number'] as num?)?.toInt() == widget.episodeNumber,
        orElse: () => null,
      );

      if (episode != null) {
        _episodeData = episode;

        if (user != null) {
          final watched = await supabase.isWatched(
            userId: user.id,
            tmdbId: widget.showId,
            mediaType: 'tv',
            seasonNumber: widget.seasonNumber,
            episodeNumber: widget.episodeNumber,
          );
          final userRating = await supabase.getUserEpisodeRating(
            userId: user.id,
            tmdbId: widget.showId,
            seasonNumber: widget.seasonNumber,
            episodeNumber: widget.episodeNumber,
          );
          final reactions = await supabase.getReactions(
            tmdbId: widget.showId,
            seasonNumber: widget.seasonNumber,
            episodeNumber: widget.episodeNumber,
          );
          final comments = await supabase.getComments(
            tmdbId: widget.showId,
            mediaType: 'tv',
            seasonNumber: widget.seasonNumber,
            episodeNumber: widget.episodeNumber,
          );
          Map<String, int> reactionCounts = {};
          for (final r in reactions) {
            final emoji = r['emoji'] as String;
            reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
          }
          if (mounted) {
            setState(() {
              _isWatched = watched;
              _userRating = userRating;
              _reactions = reactionCounts;
              _comments = List<Map<String, dynamic>>.from(comments);
            });
          }
        }

        if (mounted) setState(() => _isLoading = false);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWatched() async {
    final supabase = context.read<SupabaseService>();
    final user = supabase.currentUser;
    if (user == null) return;

    try {
      if (_isWatched) {
        await supabase.unmarkAsWatched(
          userId: user.id,
          tmdbId: widget.showId,
          mediaType: 'tv',
          seasonNumber: widget.seasonNumber,
          episodeNumber: widget.episodeNumber,
        );
      } else {
        await supabase.markAsWatched(
          userId: user.id,
          tmdbId: widget.showId,
          mediaType: 'tv',
          seasonNumber: widget.seasonNumber,
          episodeNumber: widget.episodeNumber,
          title: _episodeData?['name'] as String? ?? _showName,
          posterPath: _showPosterPath,
        );
      }
      if (mounted) setState(() => _isWatched = !_isWatched);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update watch status'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _addReaction(String emoji) async {
    final supabase = context.read<SupabaseService>();
    final user = supabase.currentUser;
    if (user == null) return;

    // Optimistic update - show reaction immediately
    final previousReactions = Map<String, int>.from(_reactions);
    setState(() {
      _reactions[emoji] = (_reactions[emoji] ?? 0) + 1;
    });

    try {
      await supabase.addReaction(
        userId: user.id,
        tmdbId: widget.showId,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
        emoji: emoji,
      );
      // Reload actual reactions from server
      final reactions = await supabase.getReactions(
        tmdbId: widget.showId,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
      );
      Map<String, int> reactionCounts = {};
      for (final r in reactions) {
        final emojiKey = r['emoji'] as String;
        reactionCounts[emojiKey] = (reactionCounts[emojiKey] ?? 0) + 1;
      }
      if (mounted) setState(() => _reactions = reactionCounts);
    } catch (e) {
      // Rollback on failure
      if (mounted) {
        setState(() => _reactions = previousReactions);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add reaction'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showRatingDialog() {
    double rating = _userRating ?? 0;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Rate Episode ${widget.episodeNumber}',
            style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating > 0 ? '${rating.toStringAsFixed(0)} / 10' : 'Tap to rate',
                style: TextStyle(
                  color: rating > 0 ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(10, (index) {
                    final starValue = index + 1.0;
                    return GestureDetector(
                      onTap: () => setState(() => rating = starValue),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(
                          rating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: rating >= starValue ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
                          size: 22,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface(context),
                foregroundColor: AppColors.text(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: rating > 0 ? () async {
                final currentRating = rating;
                final supabase = context.read<SupabaseService>();
                final user = supabase.currentUser;
                Navigator.pop(dialogContext);
                try {
                  if (user != null) {
                    await supabase.rateEpisode(
                      userId: user.id,
                      tmdbId: widget.showId,
                      seasonNumber: widget.seasonNumber,
                      episodeNumber: widget.episodeNumber,
                      rating: currentRating,
                    );
                    if (mounted) {
                      setState(() => _userRating = currentRating);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rated $currentRating/10'),
                          backgroundColor: const Color(0xFF00FF88),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to save rating'),
                        backgroundColor: const Color(0xFFFF4757),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Rate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_episodeData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Episode not found', style: TextStyle(color: AppColors.textSecondary(context))),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final episode = _episodeData!;
    final name = episode['name'] ?? '';
    final overview = episode['overview'] ?? '';
    final stillPath = episode['still_path'];
    final airDate = episode['air_date'];
    final runtime = episode['runtime'];
    final voteAverage = (episode['vote_average'] ?? 0).toDouble();

    return Scaffold(
      body: AppBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with Image
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppColors.background(context),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'E${widget.episodeNumber} • $name',
                  style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (stillPath != null)
                      CachedNetworkImage(
                        imageUrl: AppConfig.getImageUrl(stillPath, size: 'w780'),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.cardBg(context),
                          highlightColor: AppColors.cardBgStrong(context),
                          child: Container(color: Colors.grey[900]),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.cardBg(context),
                          child: Center(child: Icon(Icons.movie, size: 80, color: AppColors.iconMuted(context))),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.cardBg(context),
                        child: Center(child: Icon(Icons.movie, size: 80, color: AppColors.iconMuted(context))),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.background(context)],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Row
                    Row(
                      children: [
                        if (airDate != null) ...[
                          Icon(Icons.calendar_today, color: AppColors.textMuted(context), size: 16),
                          const SizedBox(width: 4),
                          Text(airDate, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                          const SizedBox(width: 16),
                        ],
                        if (runtime != null) ...[
                          Icon(Icons.access_time, color: AppColors.textMuted(context), size: 16),
                          const SizedBox(width: 4),
                          Text('$runtime min', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                          const SizedBox(width: 16),
                        ],
                        if (voteAverage > 0) ...[
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 16),
                          const SizedBox(width: 4),
                          Text(voteAverage.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            text: _isWatched ? 'Watched' : 'Mark as Watched',
                            icon: _isWatched ? Icons.check_circle : Icons.check_circle_outline,
                            gradient: _isWatched
                                ? const LinearGradient(colors: [Color(0xFF00FF88), Color(0xFF00CC6A)])
                                : null,
                            onPressed: () => withToggleLock(() => _toggleWatched()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showRatingDialog,
                          child: GlassContainer(
                            padding: const EdgeInsets.all(14),
                            borderRadius: BorderRadius.circular(16),
                            child: const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Overview
                    if (overview.isNotEmpty) ...[
                      Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                      const SizedBox(height: 8),
                      Text(overview, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
                      const SizedBox(height: 24),
                    ],
                    // Reactions
                    Text('Reactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['🔥', '😂', '😭', '😱', '❤️', '👏', '🤯', '💀'].map((emoji) {
                        final count = _reactions[emoji] ?? 0;
                        return GestureDetector(
                          onTap: () => _addReaction(emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                                  : AppColors.cardBg(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: count > 0
                                    ? const Color(0xFF6C63FF)
                                    : AppColors.border(context),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 18)),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      color: AppColors.text(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Rating Section
                    Text('Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 48),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    voteAverage.toStringAsFixed(1),
                                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                                  ),
                                  Text(
                                    'TMDB Rating',
                                    style: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
                                  ),
                                ],
                              ),
                              if (_userRating != null && _userRating! > 0) ...[
                                const SizedBox(width: 24),
                                Container(width: 1, height: 40, color: AppColors.border(context)),
                                const SizedBox(width: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userRating!.toStringAsFixed(0),
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFFFD93D)),
                                    ),
                                    Text(
                                      'Your Rating',
                                      style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Rating Distribution Bar
                          _buildRatingBar(voteAverage),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Comments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                        TextButton(
                          onPressed: () => context.push('/comments', extra: {
                            'tmdbId': widget.showId,
                            'mediaType': 'tv',
                            'seasonNumber': widget.seasonNumber,
                            'episodeNumber': widget.episodeNumber,
                            'title': _showName,
                            'posterPath': _showPosterPath,
                          }),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(color: AppColors.textMuted(context)),
                          ),
                        ),
                      )
                    else
                      ..._comments.take(3).map((comment) => _buildCommentCard(comment)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(double rating) {
    return Column(
      children: List.generate(10, (index) {
        final starLevel = 10 - index;
        final isActive = rating >= starLevel;
        final isHalf = !isActive && rating >= starLevel - 0.5;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '$starLevel',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isActive ? 1.0 : (isHalf ? 0.5 : 0.0),
                    backgroundColor: AppColors.cardBg(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? const Color(0xFFFFD93D) : (isHalf ? const Color(0xFFFFD93D).withValues(alpha: 0.5) : AppColors.cardBg(context)),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final username = comment['profiles']?['username'] ?? 'User';
    final content = comment['content'] ?? '';
    final createdAt = DateTime.tryParse(comment['created_at'] as String? ?? '') ?? DateTime.now();
    final isSpoiler = content.startsWith('[SPOILER]');
    final displayContent = isSpoiler ? (content.length > 10 ? content.substring(10) : '') : content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.cardBg(context),
                  child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: TextStyle(color: AppColors.text(context), fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SpoilerText(text: displayContent, isSpoiler: isSpoiler),
          ],
        ),
      ),
    );
  }
}
