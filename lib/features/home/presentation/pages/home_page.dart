import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../domain/home_cubit.dart';
import '../../domain/recommendations_cubit.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../notifications/domain/notifications_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationsCubit>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
              return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar(context)),
                SliverToBoxAdapter(child: _buildHeroSection(context, state)),
                SliverToBoxAdapter(child: _buildSearchBar(context)),
                // For You Section
                SliverToBoxAdapter(child: BlocBuilder<RecommendationsCubit, RecommendationsState>(
                  builder: (context, recState) {
                    if (recState is RecommendationsLoaded && recState.shows.isNotEmpty) {
                      return _buildSection(
                        context: context,
                        title: 'For You',
                        subtitle: 'Based on your watch history',
                        child: SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: recState.shows.length,
                            itemBuilder: (context, index) {
                              final show = recState.shows[index];
                              return ModernShowCard(id: show.id, title: show.name, posterPath: show.posterPath, rating: show.voteAverage, onTap: () => context.push('/show/${show.id}'));
                            },
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                )),
                if (state is HomeLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                else if (state is HomeLoaded) ...[
                  SliverToBoxAdapter(child: _buildSection(
                    context: context,
                    title: 'Trending Shows',
                    subtitle: 'Most popular this week',
                    onSeeAll: () => context.push('/see-all', extra: {'title': 'Trending Shows', 'type': 'trending_shows'}),
                    child: SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.trendingShows.length,
                        itemBuilder: (context, index) {
                          final show = state.trendingShows[index];
                          return ModernShowCard(id: show.id, title: show.name, posterPath: show.posterPath, rating: show.voteAverage, onTap: () => context.push('/show/${show.id}'));
                        },
                      ),
                    ),
                  )),
                  SliverToBoxAdapter(child: _buildSection(
                    context: context,
                    title: 'Trending Movies',
                    subtitle: 'Popular movies right now',
                    onSeeAll: () => context.push('/see-all', extra: {'title': 'Trending Movies', 'type': 'trending_movies'}),
                    child: SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.trendingMovies.length,
                        itemBuilder: (context, index) {
                          final movie = state.trendingMovies[index];
                          return ModernShowCard(id: movie.id, title: movie.title, posterPath: movie.posterPath, rating: movie.voteAverage, isMovie: true, onTap: () => context.push('/movie/${movie.id}'));
                        },
                      ),
                    ),
                  )),
                  SliverToBoxAdapter(child: _buildSection(
                    context: context,
                    title: 'Top Rated',
                    subtitle: 'Highest rated shows',
                    onSeeAll: () => context.push('/see-all', extra: {'title': 'Top Rated', 'type': 'top_rated'}),
                    child: SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.topRatedShows.length,
                        itemBuilder: (context, index) {
                          final show = state.topRatedShows[index];
                          return ModernShowCard(id: show.id, title: show.name, posterPath: show.posterPath, rating: show.voteAverage, onTap: () => context.push('/show/${show.id}'));
                        },
                      ),
                    ),
                  )),
                ] else if (state is HomeError)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: () => context.read<HomeCubit>().refresh(), child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          String userName = 'Guest';
          if (state is AuthAuthenticated && state.profile != null) {
            userName = state.profile!['username'] ?? 'User';
          }

          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, $userName', style: TextStyle(fontSize: 14, color: AppColors.textMuted(context))),
                  Text('NextUp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/calendar'),
                child: GlassContainer(
                  padding: const EdgeInsets.all(10),
                  borderRadius: BorderRadius.circular(14),
                  child: Icon(Icons.calendar_today_outlined, color: AppColors.text(context), size: 24),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: GlassContainer(
                  padding: const EdgeInsets.all(10),
                  borderRadius: BorderRadius.circular(14),
                  child: BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, notifState) {
                      final hasUnread = notifState is NotificationsLoaded && notifState.unreadCount > 0;
                      return Stack(
                        children: [
                          Icon(Icons.notifications_outlined, color: AppColors.text(context), size: 24),
                          if (hasUnread)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, HomeState state) {
    if (state is! HomeLoaded || state.trendingShows.isEmpty) return const SizedBox();
    final show = state.trendingShows.first;
    
    return GestureDetector(
      onTap: () => context.push('/show/${show.id}'),
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop image
              if (show.backdropUrl != null)
                CachedNetworkImage(
                  imageUrl: show.backdropUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context)),
                )
              else
                Container(color: AppColors.cardBg(context)),
              // Glass overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('TRENDING', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 8),
                    Text(show.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(show.voteAverage.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        if (show.firstAirDate != null && show.firstAirDate!.length >= 4)
                          Text(show.firstAirDate!.substring(0, 4), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                        const SizedBox(width: 12),
                        if (show.numberOfSeasons != null)
                          Text('${show.numberOfSeasons} Seasons', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              // Play button
              Positioned(
                top: 16,
                right: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.all(10),
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/search'),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textMuted(context), size: 22),
                    const SizedBox(width: 12),
                    Text('Search shows, movies...', style: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/coming-soon'),
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              child: Icon(Icons.upcoming_outlined, color: AppColors.text(context), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required String subtitle, required Widget child, VoidCallback? onSeeAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textMuted(context))),
                ],
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('See All', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary(context), size: 12),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}



