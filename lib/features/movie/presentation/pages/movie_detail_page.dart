import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/services/omdb_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/trailer_widget.dart';
import '../../../../shared/widgets/external_ratings_widget.dart';
import '../../../../shared/widgets/favorite_actor_voting_widget.dart';
import '../../../../shared/widgets/rating_dialog.dart';
import '../../../../shared/widgets/reaction_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/movie_detail_cubit.dart';
import '../../../../shared/mixins/toggle_lock_mixin.dart';

class MovieDetailPage extends StatelessWidget {
  final int movieId;

  const MovieDetailPage({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieDetailCubit(
        context.read<TmdbService>(),
        context.read<SupabaseService>(),
        context.read<OmdbService>(),
        movieId,
      ),
      child: _MovieDetailView(movieId: movieId),
    );
  }
}

class _MovieDetailView extends StatefulWidget {
  final int movieId;
  const _MovieDetailView({required this.movieId});

  @override
  State<_MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends State<_MovieDetailView> with ToggleLockMixin {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailCubit, MovieDetailState>(
      builder: (context, state) {
        if (state is MovieDetailLoading) {
          return Scaffold(body: AppBackground(child: const Center(child: CircularProgressIndicator(color: AppColors.primary))));
        }

        if (state is MovieDetailError) {
          return Scaffold(
            body: AppBackground(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<MovieDetailCubit>().loadMovieDetails(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is! MovieDetailLoaded) return Scaffold(body: AppBackground(child: const SizedBox()));

        return Scaffold(
          body: AppBackground(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppColors.background(context),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (state.movie.backdropUrl != null)
                          CachedNetworkImage(
                            imageUrl: state.movie.backdropUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppColors.cardBg(context),
                              highlightColor: AppColors.cardBgStrong(context),
                              child: Container(color: AppColors.cardBg(context)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.cardBg(context),
                              child: Center(child: Icon(Icons.movie, size: 80, color: AppColors.iconMuted(context))),
                            ),
                          )
                        else
                          Container(color: AppColors.cardBg(context), child: Center(child: Icon(Icons.movie, size: 80, color: AppColors.iconMuted(context)))),
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
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 100,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: state.movie.posterUrl != null
                                      ? CachedNetworkImage(imageUrl: state.movie.posterUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.iconMuted(context))))
                                      : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.iconMuted(context))),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(state.movie.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (state.movie.releaseDate != null && state.movie.releaseDate!.length >= 4)
                                          Text(state.movie.releaseDate!.substring(0, 4), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
                                        if (state.movie.runtime != null) ...[
                                          const SizedBox(width: 8),
                                          Text(state.movie.runtimeFormatted, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ExternalRatingsWidget(
                                      tmdbRating: state.movie.voteAverage,
                                      imdbId: state.imdbId,
                                      rottenTomatoesScore: state.rottenTomatoesScore,
                                      imdbRating: state.imdbRating,
                                      contentRating: state.contentRating,
                                      voteCount: state.movie.voteCount,
                                    ),
                                    if (state.averageRating > 0 || state.userRating != null) ...[
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            if (state.averageRating > 0) ...[
                                              Icon(Icons.people, color: AppColors.textMuted(context), size: 14),
                                              const SizedBox(width: 4),
                                              Text('NextUp: ${state.averageRating.toStringAsFixed(1)}',
                                                style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w600)),
                                            ],
                                            if (state.userRating != null) ...[
                                              const SizedBox(width: 12),
                                              Icon(Icons.star, color: const Color(0xFFFFD93D), size: 14),
                                              const SizedBox(width: 4),
                                              Text('You: ${state.userRating!.toStringAsFixed(1)}',
                                                style: TextStyle(color: const Color(0xFFFFD93D), fontSize: 12, fontWeight: FontWeight.w600)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(state.isFavorite ? Icons.favorite : Icons.favorite_outline, color: state.isFavorite ? const Color(0xFFE50914) : AppColors.text(context)),
                      onPressed: () => withToggleLock(() => context.read<MovieDetailCubit>().toggleFavorite()),
                    ),
                    IconButton(
                      icon: Icon(Icons.playlist_add, color: AppColors.text(context)),
                      onPressed: () => _showAddToListDialog(context, widget.movieId, 'movie', state.movie.title),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: AppColors.text(context)),
                      onPressed: () => Share.share('Check out ${state.movie.title} on NextUp!'),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GlassButton(
                                text: state.isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                                icon: state.isInWatchlist ? Icons.check : Icons.add,
                                gradient: state.isInWatchlist ? const LinearGradient(colors: [Color(0xFF00FF88), Color(0xFF00CC6A)]) : null,
                                onPressed: () => withToggleLock(() => context.read<MovieDetailCubit>().toggleWatchlist()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassButton(
                                text: state.isWatched ? 'Watched' : 'Mark Watched',
                                icon: state.isWatched ? Icons.check_circle : Icons.check_circle_outline,
                                gradient: state.isWatched ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]) : null,
                                onPressed: () => withToggleLock(() => context.read<MovieDetailCubit>().toggleWatched()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: GlassButton(
                            text: 'Comments',
                            icon: Icons.chat_bubble_outline,
                            gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
                            onPressed: () => context.push('/comments', extra: {'tmdbId': widget.movieId, 'mediaType': 'movie'}),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Rating Button
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => showRatingDialog(
                              context: context,
                              title: state.movie.title,
                              onRate: (rating) async {
                                final supabase = context.read<SupabaseService>();
                                final user = supabase.currentUser;
                                if (user != null) {
                                  await supabase.rateMovie(userId: user.id, tmdbId: widget.movieId, rating: rating);
                                }
                              },
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 24),
                                const SizedBox(width: 8),
                                Text('Rate This Movie', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Reactions Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildReactionsSection(context, state),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tagline
                        if (state.movie.tagline != null && state.movie.tagline!.isNotEmpty) ...[
                          Text(state.movie.tagline!, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 12),
                        ],
                        // Genres
                        if (state.movie.genres != null && state.movie.genres!.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state.movie.genres!.map((genre) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Text(genre['name'] ?? '', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Financial Info
                        if (state.movie.budget != null && state.movie.budget! > 0 || state.movie.revenue != null && state.movie.revenue! > 0) ...[
                          Row(
                            children: [
                              if (state.movie.budget != null && state.movie.budget! > 0) ...[
                                _buildFinancialItem(context, 'Budget', state.movie.budgetFormatted),
                                const SizedBox(width: 24),
                              ],
                              if (state.movie.revenue != null && state.movie.revenue! > 0)
                                _buildFinancialItem(context, 'Revenue', state.movie.revenueFormatted),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                        const SizedBox(height: 8),
                        Text(state.movie.overview ?? 'No overview available.', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                ),
                if (state.cast.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.cast.length,
                              itemBuilder: (context, index) {
                                final person = state.cast[index];
                                return GestureDetector(
                                  onTap: () => context.push('/person/${person.id}'),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 35,
                                          backgroundColor: AppColors.cardBg(context),
                                          backgroundImage: person.profileUrl != null ? CachedNetworkImageProvider(person.profileUrl!) : null,
                                          child: person.profileUrl == null ? Icon(Icons.person, color: AppColors.textMuted(context)) : null,
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(width: 70, child: Text(person.name, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Favorite Actor Voting
                if (state.cast.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: FavoriteActorVotingWidget(
                        tmdbId: widget.movieId,
                        mediaType: 'movie',
                        cast: state.cast,
                      ),
                    ),
                  ),
                if (state.videos.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: TrailerWidget(videos: state.videos),
                    ),
                  ),
                if (state.watchProviders != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: WatchProvidersWidget(providers: state.watchProviders),
                    ),
                  ),
                // Collection Section
                if (state.movie.belongsToCollection != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildCollectionSection(context, state.movie.belongsToCollection!),
                    ),
                  ),
                if (state.similarMovies.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Similar Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.similarMovies.length,
                              itemBuilder: (context, index) {
                                final movie = state.similarMovies[index];
                                return ModernShowCard(id: movie.id, title: movie.title, posterPath: movie.posterPath, rating: movie.voteAverage, isMovie: true, onTap: () => context.push('/movie/${movie.id}'));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionsSection(BuildContext context, MovieDetailLoaded state) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<SupabaseService>().getReactions(
        tmdbId: widget.movieId,
        seasonNumber: 0,
        episodeNumber: 0,
      ),
      builder: (context, snapshot) {
        final reactions = snapshot.data ?? [];
        Map<String, int> reactionCounts = {};
        for (final r in reactions) {
          final emoji = r['emoji'] as String? ?? '';
          if (emoji.isNotEmpty) {
            reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reactionCounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ReactionDisplay(reactions: reactionCounts),
              ),
            ReactionPicker(
              onReactionSelected: (emoji) async {
                final supabase = context.read<SupabaseService>();
                final user = supabase.currentUser;
                if (user == null) return;
                try {
                  await supabase.addReaction(
                    userId: user.id,
                    tmdbId: widget.movieId,
                    seasonNumber: 0,
                    episodeNumber: 0,
                    emoji: emoji,
                  );
                  // Reload reactions
                  final newReactions = await supabase.getReactions(
                    tmdbId: widget.movieId,
                    seasonNumber: 0,
                    episodeNumber: 0,
                  );
                  if (context.mounted) {
                    setState(() {});
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Failed to add reaction'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollectionSection(BuildContext context, Map<String, dynamic> collection) {
    final name = collection['name'] ?? '';
    final posterPath = collection['poster_path'];
    final backdropPath = collection['backdrop_path'];
    final collectionId = collection['id'];

    if (name.isEmpty) return const SizedBox();

    return GestureDetector(
      onTap: () {
        // Navigate to a collection page or show dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Collection: $name'), backgroundColor: AppColors.electricPurple),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.cardBg(context),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: AppConfig.getImageUrl(posterPath, size: 'w154'),
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                      )
                    : Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Part of Collection', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
          ],
        ),
      ),
    );
  }

  void _showAddToListDialog(BuildContext context, int tmdbId, String mediaType, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.playlist_add, color: AppColors.electricPurple),
            const SizedBox(width: 8),
            Text('Add to List', style: TextStyle(color: AppColors.text(context))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add "$title" to a custom list', style: TextStyle(color: AppColors.textSecondary(context))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push('/custom-lists');
              },
              icon: const Icon(Icons.playlist_play),
              label: const Text('Go to My Lists'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricPurple),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
