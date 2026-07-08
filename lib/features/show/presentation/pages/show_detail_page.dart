import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/omdb_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/trailer_widget.dart';
import '../../../../shared/widgets/external_ratings_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/show_detail_cubit.dart';

class ShowDetailPage extends StatelessWidget {
  final int showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShowDetailCubit(
        context.read<TmdbService>(),
        context.read<SupabaseService>(),
        context.read<OmdbService>(),
        showId,
      ),
      child: _ShowDetailView(showId: showId),
    );
  }
}

class _ShowDetailView extends StatefulWidget {
  final int showId;
  const _ShowDetailView({required this.showId});

  @override
  State<_ShowDetailView> createState() => _ShowDetailViewState();
}

class _ShowDetailViewState extends State<_ShowDetailView> {
  int _voteRefreshKey = 0;

  void _refreshVotes() {
    setState(() {
      _voteRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShowDetailCubit, ShowDetailState>(
      builder: (context, state) {
        if (state is ShowDetailLoading) {
          return AppBackground(child: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }

        if (state is ShowDetailError) {
          return AppBackground(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ShowDetailCubit>().loadShowDetails(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! ShowDetailLoaded) return AppBackground(child: const SizedBox());

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
                        if (state.show.backdropUrl != null)
                          CachedNetworkImage(
                            imageUrl: state.show.backdropUrl!,
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
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: state.show.posterUrl != null
                                      ? CachedNetworkImage(imageUrl: state.show.posterUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.iconMuted(context))))
                                      : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.iconMuted(context))),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(state.show.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        RatingBadge(rating: state.show.voteAverage),
                                        const SizedBox(width: 8),
                                        if (state.show.firstAirDate != null && state.show.firstAirDate!.length >= 4)
                                          Text(state.show.firstAirDate!.substring(0, 4), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
                                        if (state.show.numberOfSeasons != null) ...[
                                          const SizedBox(width: 8),
                                          Text('${state.show.numberOfSeasons} Seasons', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ExternalRatingsWidget(
                                      imdbId: state.imdbId,
                                      rottenTomatoesScore: state.rottenTomatoesScore,
                                      imdbRating: state.imdbRating,
                                      contentRating: state.contentRating,
                                      voteCount: state.show.voteCount,
                                    ),
                                    // NextUp User Ratings
                                    if (state.averageRating > 0 || state.userRating != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
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
                      onPressed: () => context.read<ShowDetailCubit>().toggleFavorite(),
                    ),
                    IconButton(
                      icon: Icon(Icons.playlist_add, color: AppColors.text(context)),
                      onPressed: () => _showAddToListDialog(context, widget.showId, 'tv', state.show.name),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: AppColors.text(context)),
                      onPressed: () => Share.share('Check out ${state.show.name} on NextUp!'),
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
                                onPressed: () => context.read<ShowDetailCubit>().toggleWatchlist(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassButton(
                                text: 'Comments',
                                icon: Icons.chat_bubble_outline,
                                gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
                                onPressed: () => context.push('/comments', extra: {'tmdbId': widget.showId, 'mediaType': 'tv'}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Rating Button
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _showRatingDialog(context, widget.showId, 'tv', state.show.name),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 24),
                                const SizedBox(width: 8),
                                Text('Rate This Show', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tagline
                        if (state.show.tagline != null && state.show.tagline!.isNotEmpty) ...[
                          Text(state.show.tagline!, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 12),
                        ],
                        // Genres
                        if (state.show.genres != null && state.show.genres!.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state.show.genres!.map((genre) {
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
                        // Status
                        if (state.show.status != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: state.show.status == 'Returning Series' ? const Color(0xFF00FF88).withOpacity(0.2) : const Color(0xFFFF4757).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(state.show.status!, style: TextStyle(color: state.show.status == 'Returning Series' ? const Color(0xFF00FF88) : const Color(0xFFFF4757), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              if (state.show.networks != null && state.show.networks!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(state.show.networks!.first['name'] ?? '', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                        const SizedBox(height: 8),
                        Text(state.show.overview ?? 'No overview available.', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                ),
                // Seasons List
                if (state.show.seasons != null && state.show.seasons!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seasons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          const SizedBox(height: 12),
                          ...state.show.seasons!.where((s) => s.seasonNumber > 0).map((season) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => context.push('/show/$widget.showId/season/${season.seasonNumber}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        color: AppColors.cardBg(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${season.seasonNumber}',
                                          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(season.name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600)),
                                          Text('${season.episodeCount} episodes', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
                                  ],
                                ),
                              ),
                            ),
                          )),
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
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => context.push('/person/${person.id}'),
                                        child: CircleAvatar(
                                          radius: 35,
                                          backgroundColor: AppColors.cardBg(context),
                                          backgroundImage: person.profileUrl != null ? CachedNetworkImageProvider(person.profileUrl!) : null,
                                          child: person.profileUrl == null ? Icon(Icons.person, color: AppColors.textMuted(context)) : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(width: 70, child: Text(person.name, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ],
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
                      child: _buildFavoriteActorSection(context, widget.showId, 'tv', state.cast),
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
                if (state.similarShows.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Similar Shows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.similarShows.length,
                              itemBuilder: (context, index) {
                                final show = state.similarShows[index];
                                return ModernShowCard(id: show.id, title: show.name, posterPath: show.posterPath, rating: show.voteAverage, onTap: () => context.push('/show/${show.id}'));
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

  void _showRatingDialog(BuildContext context, int tmdbId, String mediaType, String title) {
    double rating = 0;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rate $title', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(10, (index) {
                  final starValue = index + 1.0;
                  return GestureDetector(
                    onTap: () => setState(() => rating = starValue),
                    child: Icon(
                      rating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: rating >= starValue ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
                      size: 32,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context)))),
            ElevatedButton(
              onPressed: rating > 0 ? () async {
                final supabase = context.read<SupabaseService>();
                final user = supabase.currentUser;
                if (user != null) {
                  await supabase.rateShow(userId: user.id, tmdbId: tmdbId, rating: rating);
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rated $rating/10'), backgroundColor: const Color(0xFF00FF88), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                );
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Rate'),
            ),
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

  Widget _buildFavoriteActorSection(BuildContext context, int tmdbId, String mediaType, List<dynamic> cast) {
    final supabase = context.read<SupabaseService>();
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Who's Your Favorite?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 4),
        Text('Vote for your favorite actor in this show', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
        const SizedBox(height: 12),
        // Show voting results if user has voted, otherwise show voting UI
        FutureBuilder<Map<String, dynamic>?>(
          key: ValueKey(_voteRefreshKey),
          future: userId != null ? supabase.getUserFavoriteActorVote(userId: userId, tmdbId: tmdbId, mediaType: mediaType) : null,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return SizedBox();
            }
            final userVote = snapshot.data;
            if (userVote != null) {
              // User has voted - show results
              return _buildVotingResults(context, tmdbId, mediaType, userVote, cast);
            }
            // User hasn't voted - show voting UI
            return _buildVotingUI(context, tmdbId, mediaType, cast, userId);
          },
        ),
      ],
    );
  }

  Widget _buildVotingUI(BuildContext context, int tmdbId, String mediaType, List<dynamic> cast, String? userId) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length.clamp(0, 10), // Show max 10 actors
        itemBuilder: (context, index) {
          final person = cast[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                if (userId == null) return;
                try {
                  final supabase = context.read<SupabaseService>();
                  await supabase.voteFavoriteActor(
                    userId: userId,
                    tmdbId: tmdbId,
                    mediaType: mediaType,
                    personId: person.id,
                    characterName: person.character,
                  );
                  if (context.mounted) {
                    _refreshVotes();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to vote. Please try again.'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border(context), width: 2),
                      image: person.profileUrl != null
                          ? DecorationImage(image: CachedNetworkImageProvider(person.profileUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: person.profileUrl == null
                        ? Icon(Icons.person, color: AppColors.textMuted(context), size: 30)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      person.name,
                      style: TextStyle(color: AppColors.text(context), fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Vote', style: TextStyle(color: AppColors.electricPurple, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVotingResults(BuildContext context, int tmdbId, String mediaType, Map<String, dynamic> userVote, List<dynamic> cast) {
    final supabase = context.read<SupabaseService>();
    final votedPersonId = userVote['person_id'] as int? ?? 0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.getFavoriteActorResults(tmdbId: tmdbId, mediaType: mediaType),
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const SizedBox();
        }

        return Column(
          children: [
            // Results list
            ...results.map((result) {
              final personId = result['person_id'] as int? ?? 0;
              final characterName = result['character_name'] as String? ?? 'Unknown';
              final percentage = result['percentage'] as int? ?? 0;
              final isUserVote = personId == votedPersonId;
              dynamic person;
              for (final p in cast) {
                if (p.id == personId) { person = p; break; }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      // Actor avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUserVote ? AppColors.electricPurple : AppColors.border(context),
                            width: isUserVote ? 2 : 1,
                          ),
                          image: person?.profileUrl != null
                              ? DecorationImage(image: CachedNetworkImageProvider(person!.profileUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: person?.profileUrl == null
                            ? Icon(Icons.person, color: AppColors.textMuted(context), size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Name and character
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    person?.name ?? 'Unknown',
                                    style: TextStyle(
                                      color: AppColors.text(context),
                                      fontWeight: isUserVote ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isUserVote)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.electricPurple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Your vote', style: TextStyle(color: AppColors.electricPurple, fontSize: 10)),
                                  ),
                              ],
                            ),
                            Text(characterName, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Percentage bar and value
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              color: isUserVote ? AppColors.electricPurple : AppColors.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: AppColors.cardBg(context),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isUserVote ? AppColors.electricPurple : AppColors.primary,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

