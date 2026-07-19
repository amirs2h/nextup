import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../shared/models/movie_model.dart';
import '../../domain/home_cubit.dart';
import '../../domain/recommendations_cubit.dart';
import '../../domain/friends_activity_cubit.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../notifications/domain/notifications_cubit.dart';
import '../widgets/friends_activity_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomePageView();
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<_HomePageView> {
  late PageController _heroPageController;
  Timer? _heroTimer;
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController(viewportFraction: 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reloadData();
      _startHeroAutoPlay();
    });
  }

  void _startHeroAutoPlay() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_heroPageController.hasClients) return;
      final state = context.read<HomeCubit>().state;
      if (state is! HomeLoaded) return;
      final total = _getHeroItems(state).length;
      if (total <= 1) return;
      _heroIndex = (_heroIndex + 1) % total;
      _heroPageController.animateToPage(
        _heroIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  List<dynamic> _getHeroItems(HomeLoaded state) {
    final items = <dynamic>[];
    items.addAll(state.trendingShows.take(5));
    items.addAll(state.trendingMovies.take(5));
    return items;
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  void _reloadData() {
    context.read<HomeCubit>().refresh();
    context.read<RecommendationsCubit>().loadRecommendations();
    context.read<FriendsActivityCubit>().loadFriendsActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildAppBar(context)),
                  SliverToBoxAdapter(child: _buildHeroSection(context, state)),
                  SliverToBoxAdapter(child: _buildSearchBar(context)),
                  // Friends Activity Section
                  SliverToBoxAdapter(child: BlocBuilder<FriendsActivityCubit, FriendsActivityState>(
                    builder: (context, faState) {
                      if (faState is FriendsActivityLoaded || faState is FriendsActivityLoading) {
                        return _buildSection(
                          context: context,
                          title: 'Friends Are Watching',
                          subtitle: 'What your friends are watching right now',
                          onSeeAll: () => context.push('/activity'),
                          child: const FriendsActivitySection(),
                        );
                      }
                      return const SizedBox();
                    },
                  )),
                  // For You Section (Shows)
                  SliverToBoxAdapter(child: BlocBuilder<RecommendationsCubit, RecommendationsState>(
                    builder: (context, recState) {
                      if (recState is RecommendationsLoaded && recState.shows.isNotEmpty) {
                        return _buildSection(
                          context: context,
                          title: 'For You — Shows',
                          subtitle: 'Based on your watch history',
                          child: SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: recState.shows.length,
                              itemBuilder: (context, index) {
                                final show = recState.shows[index];
                                return ModernShowCard(id: show.id, title: show.name, posterPath: show.posterPath, rating: show.voteAverage, onTap: () async {
                                  await context.push('/show/${show.id}');
                                  if (mounted) _reloadData();
                                });
                              },
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  )),
                  // For You Section (Movies)
                  SliverToBoxAdapter(child: BlocBuilder<RecommendationsCubit, RecommendationsState>(
                    builder: (context, recState) {
                      if (recState is RecommendationsLoaded && recState.movies.isNotEmpty) {
                        return _buildSection(
                          context: context,
                          title: 'For You — Movies',
                          subtitle: 'Based on your watch history',
                          child: SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: recState.movies.length,
                              itemBuilder: (context, index) {
                                final movie = recState.movies[index];
                                return ModernShowCard(id: movie.id, title: movie.title, posterPath: movie.posterPath, rating: movie.voteAverage, isMovie: true, onTap: () async {
                                  await context.push('/movie/${movie.id}');
                                  if (mounted) _reloadData();
                                });
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
                            return ModernShowCard(id: show.id, title: show.name, posterPath: show.posterPath, rating: show.voteAverage, onTap: () async {
                              await context.push('/show/${show.id}');
                              if (mounted) _reloadData();
                            });
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
                            return ModernShowCard(id: movie.id, title: movie.title, posterPath: movie.posterPath, rating: movie.voteAverage, isMovie: true, onTap: () async {
                              await context.push('/movie/${movie.id}');
                              if (mounted) _reloadData();
                            });
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
                            return ModernShowCard(id: show.id, title: show.name, posterPath: show.posterPath, rating: show.voteAverage, onTap: () async {
                              await context.push('/show/${show.id}');
                              if (mounted) _reloadData();
                            });
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
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
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
    if (state is! HomeLoaded) return const SizedBox();
    final items = _getHeroItems(state);
    if (items.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: items.length,
            onPageChanged: (index) => setState(() => _heroIndex = index),
            itemBuilder: (context, index) {
              final item = items[index];
              final isShow = item is ShowModel;
              final id = isShow ? item.id : (item as MovieModel).id;
              final name = isShow ? item.name : (item as MovieModel).title;
              final backdropUrl = isShow ? item.backdropUrl : (item as MovieModel).backdropUrl;
              final rating = isShow ? item.voteAverage : (item as MovieModel).voteAverage;
              final year = isShow
                  ? (item.firstAirDate != null && item.firstAirDate!.length >= 4 ? item.firstAirDate!.substring(0, 4) : null)
                  : (item.releaseDate != null && item.releaseDate!.length >= 4 ? item.releaseDate!.substring(0, 4) : null);
              final extra = isShow && item.numberOfSeasons != null ? '${item.numberOfSeasons} Seasons' : null;

              return GestureDetector(
                onTap: () async {
                  await context.push(isShow ? '/show/$id' : '/movie/$id');
                  if (mounted) _reloadData();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Backdrop
                        if (backdropUrl != null)
                          CachedNetworkImage(
                            imageUrl: backdropUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context)),
                          )
                        else
                          Container(color: AppColors.cardBg(context)),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
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
                                  color: (isShow ? AppColors.primary : AppColors.electricPurple).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isShow ? 'TRENDING SHOW' : 'TRENDING MOVIE',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 15),
                                  const SizedBox(width: 4),
                                  Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (year != null) ...[
                                    const SizedBox(width: 10),
                                    Text(year, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                  ],
                                  if (extra != null) ...[
                                    const SizedBox(width: 10),
                                    Text(extra, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Play icon
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
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        if (items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (index) {
              final isActive = index == _heroIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.textMuted(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
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
