import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/trailer_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/movie_detail_cubit.dart';

class MovieDetailPage extends StatelessWidget {
  final int movieId;

  const MovieDetailPage({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieDetailCubit(
        context.read<TmdbService>(),
        context.read<SupabaseService>(),
        movieId,
      ),
      child: _MovieDetailView(movieId: movieId),
    );
  }
}

class _MovieDetailView extends StatelessWidget {
  final int movieId;
  const _MovieDetailView({required this.movieId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailCubit, MovieDetailState>(
      builder: (context, state) {
        if (state is MovieDetailLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))));
        }

        if (state is MovieDetailError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
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
          );
        }

        if (state is! MovieDetailLoaded) return const Scaffold(body: SizedBox());

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
                              baseColor: Colors.grey[900]!,
                              highlightColor: Colors.grey[800]!,
                              child: Container(color: Colors.grey[900]),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: const Center(child: Icon(Icons.movie, size: 80, color: Colors.white24)),
                            ),
                          )
                        else
                          Container(color: Colors.grey[900], child: const Center(child: Icon(Icons.movie, size: 80, color: Colors.white24))),
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
                                  child: state.movie.posterUrl != null
                                      ? CachedNetworkImage(imageUrl: state.movie.posterUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.grey[800], child: const Icon(Icons.movie, color: Colors.white24)))
                                      : Container(color: Colors.grey[800], child: const Icon(Icons.movie, color: Colors.white24)),
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
                                        RatingBadge(rating: state.movie.voteAverage, size: 0.9),
                                        const SizedBox(width: 8),
                                        if (state.movie.releaseDate != null && state.movie.releaseDate!.length >= 4)
                                          Text(state.movie.releaseDate!.substring(0, 4), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
                                        if (state.movie.runtime != null) ...[
                                          const SizedBox(width: 8),
                                          Text(state.movie.runtimeFormatted, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
                                        ],
                                      ],
                                    ),
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
                      onPressed: () => context.read<MovieDetailCubit>().toggleFavorite(),
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
                                onPressed: () => context.read<MovieDetailCubit>().toggleWatchlist(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassButton(
                                text: state.isWatched ? 'Watched' : 'Mark Watched',
                                icon: state.isWatched ? Icons.check_circle : Icons.check_circle_outline,
                                gradient: state.isWatched ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]) : null,
                                onPressed: () => context.read<MovieDetailCubit>().toggleWatched(),
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
                            onPressed: () => context.push('/comments', extra: {'tmdbId': movieId, 'mediaType': 'movie'}),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Rating Button
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _showRatingDialog(context, movieId, 'movie', state.movie.title),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                return Padding(
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
                                );
                              },
                            ),
                          ),
                        ],
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
                  await supabase.rateMovie(userId: user.id, tmdbId: tmdbId, rating: rating);
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
}
