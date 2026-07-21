import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../shared/models/movie_model.dart';

import '../../../achievements/domain/achievements_cubit.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/profile_cubit.dart';
import '../../domain/favorites_cubit.dart';
import '../../../watchlist/domain/watchlist_cubit.dart';
import '../../domain/watch_history_cubit.dart';
import '../../../shared_lists/domain/shared_lists_cubit.dart';
import '../../../custom_lists/domain/custom_lists_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfilePageView();
  }
}

class _ProfilePageView extends StatefulWidget {
  const _ProfilePageView();

  @override
  State<_ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<_ProfilePageView> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadProfile(authState.user.id);
      context.read<FavoritesCubit>().loadFavorites();
      context.read<WatchlistCubit>().loadWatchlist();
      context.read<WatchHistoryCubit>().loadHistory();
      context.read<AchievementsCubit>().loadAchievements();
      context.read<CustomListsCubit>().loadCustomLists();
      context.read<SharedListsCubit>().loadSharedLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
          if (authState is AuthUnauthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('Please login to view your profile', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Login')),
                ],
              ),
            );
          }

          String username = 'User';
          String email = '';
          String? avatarUrl;
          String bio = '';
          if (authState is AuthAuthenticated) {
            username = authState.profile?['username'] ?? 'User';
            email = authState.user.email ?? '';
            avatarUrl = authState.profile?['avatar_url'];
            bio = authState.profile?['bio'] ?? '';
          }

          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              int followersCount = 0;
              int followingCount = 0;
              int watchlistCount = 0;
              List<Map<String, dynamic>> followers = [];
              List<Map<String, dynamic>> following = [];

              if (state is ProfileLoaded) {
                followersCount = state.followersCount;
                followingCount = state.followingCount;
                watchlistCount = state.watchlistCount;
                followers = state.followers;
                following = state.following;
              }

              return RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(context, username, email, avatarUrl, bio, followersCount, followingCount, watchlistCount, followers, following),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildQuickStats(context, watchlistCount, followersCount, followingCount, followers, following),
                            const SizedBox(height: 16),
                            _buildLevelAndBadges(context),
                            const SizedBox(height: 16),
                            _buildActionButtons(context),
                            const SizedBox(height: 24),
                            _buildFavoritesCarousel(context),
                            const SizedBox(height: 24),
                            _buildWatchlistCarousel(context),
                            const SizedBox(height: 24),
                            _buildHistoryCarousel(context),
                            const SizedBox(height: 24),
                            _buildCustomListsCarousel(context),
                            const SizedBox(height: 24),
                            _buildSharedListsCarousel(context),
                            const SizedBox(height: 24),
                            _buildUserContent(context),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String username, String email, String? avatarUrl, String bio, int followersCount, int followingCount, int watchlistCount, List<Map<String, dynamic>> followers, List<Map<String, dynamic>> following) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, watchlistState) {
        final authState = context.read<AuthCubit>().state;
        String? headerUrl;
        if (authState is AuthAuthenticated) {
          headerUrl = authState.profile?['header_image_url'] as String?;
        }
        String? backdropUrl = headerUrl;
        if (backdropUrl == null && watchlistState is WatchlistLoaded && watchlistState.items.isNotEmpty) {
          final firstItem = watchlistState.items.first;
          if (firstItem.mediaType == 'tv') {
            final show = firstItem.model as ShowModel;
            backdropUrl = show.backdropUrl ?? show.posterUrl;
          } else {
            final movie = firstItem.model as MovieModel;
            backdropUrl = movie.backdropUrl ?? movie.posterUrl;
          }
        }

        return Column(
          children: [
            // Full-width backdrop banner
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD), Color(0xFFE50914)],
                    ),
                  ),
                  child: backdropUrl != null
                      ? CachedNetworkImage(
                          imageUrl: backdropUrl,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD), Color(0xFFE50914)],
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.movie_outlined, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                        ),
                ),
                // Gradient overlay
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        AppColors.background(context).withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Settings button top-right
                Positioned(
                  top: 50,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.settings_outlined, color: Colors.white.withValues(alpha: 0.8), size: 22),
                    ),
                  ),
                ),
              ],
            ),
            // Avatar overlapping banner
            Transform.translate(
              offset: const Offset(0, -50),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
                      border: Border.all(color: AppColors.background(context), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Center(
                                child: Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40),
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(username, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        bio,
                        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context, int watchlist, int followers, int following, List<Map<String, dynamic>> followersList, List<Map<String, dynamic>> followingList) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(context, 'Watchlist', watchlist),
          Container(width: 1, height: 40, color: AppColors.divider(context)),
          GestureDetector(
            onTap: () => _showFollowing(followingList),
            child: _buildStatItem(context, 'Following', following),
          ),
          Container(width: 1, height: 40, color: AppColors.divider(context)),
          GestureDetector(
            onTap: () => _showFollowers(followersList),
            child: _buildStatItem(context, 'Followers', followers),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
      ],
    );
  }

  Widget _buildLevelAndBadges(BuildContext context) {
    return BlocBuilder<AchievementsCubit, AchievementsState>(
      builder: (context, achState) {
        if (achState is! AchievementsLoaded) return const SizedBox();
        final level = achState.level;
        final currentXp = achState.currentXp;
        final xpToNext = achState.xpToNextLevel;
        final topBadges = achState.achievements.where((a) => a.isUnlocked).toList()
          ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
        final displayBadges = topBadges.take(3).toList();

        if (displayBadges.isEmpty && level == 1) return const SizedBox();

        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Level + XP bar
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Center(
                      child: Text('$level', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Level $level', style: TextStyle(color: AppColors.text(context), fontSize: 14, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('$currentXp / $xpToNext XP', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: xpToNext > 0 ? currentXp / xpToNext : 0,
                            minHeight: 6,
                            backgroundColor: AppColors.cardBg(context),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (displayBadges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: displayBadges.map((badge) {
                    return GestureDetector(
                      onTap: () => context.push('/achievements'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: badge.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badge.color.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badge.icon, color: badge.color, size: 13),
                            const SizedBox(width: 5),
                            Text(badge.title, style: TextStyle(color: badge.color, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesCarousel(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        if (state is! FavoritesLoaded) return const SizedBox();
        final shows = state.shows;
        final movies = state.movies;
        final totalItems = shows.length + movies.length;
        if (totalItems == 0) return const SizedBox();
        return _buildCarouselSection(
          context,
          title: 'Favorites',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE50914),
          onSeeAll: () => context.push('/favorites'),
          itemCount: totalItems > 10 ? 10 : totalItems,
          itemBuilder: (context, index) {
            final isMovie = index >= shows.length;
            final id = isMovie ? movies[index - shows.length].id : shows[index].id;
            final title = isMovie ? movies[index - shows.length].title : shows[index].name;
            final posterUrl = isMovie ? movies[index - shows.length].posterUrl : shows[index].posterUrl;
            return _buildCarouselItem(context, title: title, posterUrl: posterUrl, onTap: () async {
              await context.push(isMovie ? '/movie/$id' : '/show/$id');
              if (mounted) _loadData();
            });
          },
        );
      },
    );
  }

  Widget _buildWatchlistCarousel(BuildContext context) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, state) {
        if (state is! WatchlistLoaded) return const SizedBox();
        final items = state.items;
        if (items.isEmpty) return const SizedBox();
        return _buildCarouselSection(
          context,
          title: 'Watchlist',
          icon: Icons.bookmark_rounded,
          color: const Color(0xFF6C63FF),
          onSeeAll: () => context.go('/watchlist'),
          itemCount: items.length > 10 ? 10 : items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isMovie = item.mediaType == 'movie';
            final id = isMovie ? (item.model as MovieModel).id : (item.model as ShowModel).id;
            final title = isMovie ? (item.model as MovieModel).title : (item.model as ShowModel).name;
            final posterUrl = isMovie ? (item.model as MovieModel).posterUrl : (item.model as ShowModel).posterUrl;
            return _buildCarouselItem(context, title: title, posterUrl: posterUrl, onTap: () async {
              await context.push(isMovie ? '/movie/$id' : '/show/$id');
              if (mounted) _loadData();
            });
          },
        );
      },
    );
  }

  Widget _buildHistoryCarousel(BuildContext context) {
    return BlocBuilder<WatchHistoryCubit, WatchHistoryState>(
      builder: (context, state) {
        if (state is! WatchHistoryLoaded) return const SizedBox();
        final shows = state.shows.values.toList();
        final movies = state.movies.values.toList();
        final totalItems = shows.length + movies.length;
        if (totalItems == 0) return const SizedBox();
        return _buildCarouselSection(
          context,
          title: 'Watch History',
          icon: Icons.history_rounded,
          color: const Color(0xFF00CC6A),
          onSeeAll: () => context.push('/watch-history'),
          itemCount: totalItems > 10 ? 10 : totalItems,
          itemBuilder: (context, index) {
            final isMovie = index >= shows.length;
            final id = isMovie ? movies[index - shows.length].id : shows[index].id;
            final title = isMovie ? movies[index - shows.length].title : shows[index].name;
            final posterUrl = isMovie ? movies[index - shows.length].posterUrl : shows[index].posterUrl;
            return _buildCarouselItem(context, title: title, posterUrl: posterUrl, onTap: () async {
              await context.push(isMovie ? '/movie/$id' : '/show/$id');
              if (mounted) _loadData();
            });
          },
        );
      },
    );
  }

  Widget _buildCustomListsCarousel(BuildContext context) {
    return BlocBuilder<CustomListsCubit, CustomListsState>(
      builder: (context, state) {
        if (state is! CustomListsLoaded) return const SizedBox();
        final lists = state.lists;
        if (lists.isEmpty) return const SizedBox();
        return _buildCarouselSection(
          context,
          title: 'My Lists',
          icon: Icons.playlist_play_rounded,
          color: const Color(0xFF9D4EDD),
          onSeeAll: () => context.push('/custom-lists'),
          itemCount: lists.length > 10 ? 10 : lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            final name = list['name'] ?? 'Untitled';
            final description = list['description'] ?? '';
            final isPublic = list['is_public'] ?? false;
            final listId = list['id'];
            return _buildListItem(
              context,
              name: name,
              description: description,
              icon: isPublic ? Icons.public : Icons.lock_outline,
              color: const Color(0xFF9D4EDD),
              onTap: () {
                if (listId != null) context.push('/custom-list/$listId', extra: name);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSharedListsCarousel(BuildContext context) {
    return BlocBuilder<SharedListsCubit, SharedListsState>(
      builder: (context, state) {
        if (state is! SharedListsLoaded) return const SizedBox();
        final lists = state.lists;
        if (lists.isEmpty) return const SizedBox();
        return _buildCarouselSection(
          context,
          title: 'Shared Lists',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF00B4D8),
          onSeeAll: () => context.push('/shared-lists'),
          itemCount: lists.length > 10 ? 10 : lists.length,
          itemBuilder: (context, index) {
            final listData = lists[index];
            final list = listData['shared_lists'] ?? listData;
            final name = list['name'] ?? 'Untitled';
            final description = list['description'] ?? '';
            final listId = list['id'];
            return _buildListItem(
              context,
              name: name,
              description: description,
              icon: Icons.people_rounded,
              color: const Color(0xFF00B4D8),
              onTap: () {
                if (listId != null) context.push('/shared-list/$listId');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, {required String name, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.15)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: TextStyle(color: AppColors.text(context), fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: AppColors.textMuted(context), fontSize: 11, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselSection(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onSeeAll, required int itemCount, required Widget Function(BuildContext, int) itemBuilder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('See All', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(BuildContext context, {required String title, String? posterUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 145,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: posterUrl != null
                    ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))))
                    : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            text: 'Edit Profile',
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/edit-profile'),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthAuthenticated) {
              final username = authState.profile?['username'] ?? 'User';
              Share.share('Check out $username\'s profile on NextUp!');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(Icons.share_rounded, color: AppColors.text(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserContent(BuildContext context) {
    return Column(
      children: [
        _buildContentCard(context, icon: Icons.bookmark_rounded, title: 'My Watchlist', subtitle: 'Shows and movies to watch', color: const Color(0xFF6C63FF), onTap: () => context.go('/watchlist')),
        _buildContentCard(context, icon: Icons.favorite_rounded, title: 'Favorites', subtitle: 'Your favorite shows and movies', color: const Color(0xFFE50914), onTap: () => context.push('/favorites')),
        _buildContentCard(context, icon: Icons.history_rounded, title: 'Watch History', subtitle: 'Shows and movies you\'ve watched', color: const Color(0xFF00CC6A), onTap: () => context.push('/watch-history')),
        _buildContentCard(context, icon: Icons.playlist_play_rounded, title: 'My Lists', subtitle: 'Custom collections', color: const Color(0xFF9D4EDD), onTap: () => context.push('/custom-lists')),
        _buildContentCard(context, icon: Icons.people_alt_rounded, title: 'Shared Lists', subtitle: 'Lists with friends', color: const Color(0xFF6C63FF), onTap: () => context.push('/shared-lists')),
        _buildContentCard(context, icon: Icons.leaderboard_rounded, title: 'Rankings', subtitle: 'Compare with friends', color: const Color(0xFFFFD93D), onTap: () => context.push('/rankings')),
        _buildContentCard(context, icon: Icons.bar_chart_rounded, title: 'Statistics', subtitle: 'Your watching stats', color: const Color(0xFF00CC6A), onTap: () => context.push('/stats')),
        _buildContentCard(context, icon: Icons.emoji_events_rounded, title: 'Achievements', subtitle: 'Your badges and milestones', color: const Color(0xFFFFD93D), onTap: () => context.push('/achievements')),
        _buildContentCard(context, icon: Icons.people_rounded, title: 'Activity', subtitle: 'What your friends are watching', color: const Color(0xFF6C63FF), onTap: () => context.push('/activity')),
        _buildContentCard(context, icon: Icons.settings_rounded, title: 'Settings', subtitle: 'Theme, language, notifications', color: AppColors.textSecondary(context), onTap: () => context.push('/settings')),
      ],
    );
  }

  Widget _buildContentCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          opacity: 0.06,
          borderColor: color.withValues(alpha: 0.1),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showFollowing(List<Map<String, dynamic>> following) {
    showDialog(
      context: context,
      builder: (dialogContext) => _FollowingDialog(
        following: following,
        onUnfollow: (uid) async {
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthAuthenticated) {
            try {
              await context.read<ProfileCubit>().unfollowUser(authState.user.id, uid);
              if (mounted) _loadData();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Failed to unfollow. Please try again.'), backgroundColor: AppColors.error),
                );
              }
            }
          }
        },
      ),
    );
  }

  void _showFollowers(List<Map<String, dynamic>> followers) {
    // Get list of following IDs to check who we already follow
    final profileState = context.read<ProfileCubit>().state;
    final followingIds = <String>{};
    if (profileState is ProfileLoaded) {
      for (final f in profileState.following) {
        followingIds.add(f['following_id'] as String);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _FollowersDialog(
        followers: followers,
        followingIds: followingIds,
        onFollowBack: (uid) async {
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthAuthenticated) {
            try {
              await context.read<ProfileCubit>().followUser(authState.user.id, uid);
              if (mounted) _loadData();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Failed to follow. Please try again.'), backgroundColor: AppColors.error),
                );
              }
            }
          }
        },
      ),
    );
  }
}

// Following Dialog with Unfollow functionality
class _FollowingDialog extends StatefulWidget {
  final List<Map<String, dynamic>> following;
  final Future<void> Function(String uid) onUnfollow;

  const _FollowingDialog({required this.following, required this.onUnfollow});

  @override
  State<_FollowingDialog> createState() => _FollowingDialogState();
}

class _FollowingDialogState extends State<_FollowingDialog> {
  String? _unfollowingUid;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Following', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      children: [
        if (widget.following.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Not following anyone yet', style: TextStyle(color: AppColors.textMuted(context))),
          )
        else
          ...widget.following.map((user) {
            final uname = user['profiles']?['username'] ?? 'User';
            final uid = user['following_id'];
            final isUnfollowing = _unfollowingUid == uid;
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                context.push('/user/$uid');
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(uname.isNotEmpty ? uname[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(uname, style: TextStyle(color: AppColors.text(context), fontSize: 16))),
                  TextButton(
                    onPressed: isUnfollowing ? null : () async {
                      setState(() => _unfollowingUid = uid);
                      await widget.onUnfollow(uid);
                      if (mounted) setState(() => _unfollowingUid = null);
                    },
                    child: isUnfollowing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF4757)))
                        : const Text('Unfollow', style: TextStyle(color: Color(0xFFFF4757))),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// Followers Dialog with Follow Back functionality
class _FollowersDialog extends StatefulWidget {
  final List<Map<String, dynamic>> followers;
  final Set<String> followingIds;
  final Future<void> Function(String uid) onFollowBack;

  const _FollowersDialog({required this.followers, required this.followingIds, required this.onFollowBack});

  @override
  State<_FollowersDialog> createState() => _FollowersDialogState();
}

class _FollowersDialogState extends State<_FollowersDialog> {
  String? _followingUid;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Followers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      children: [
        if (widget.followers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No followers yet', style: TextStyle(color: AppColors.textMuted(context))),
          )
        else
          ...widget.followers.map((user) {
            final uname = user['profiles']?['username'] ?? 'User';
            final uid = user['follower_id'] as String;
            final alreadyFollowing = widget.followingIds.contains(uid);
            final isFollowing = _followingUid == uid;
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                context.push('/user/$uid');
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(uname.isNotEmpty ? uname[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(uname, style: TextStyle(color: AppColors.text(context), fontSize: 16))),
                  if (alreadyFollowing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Following', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                    )
                  else
                    TextButton(
                      onPressed: isFollowing ? null : () async {
                        setState(() => _followingUid = uid);
                        await widget.onFollowBack(uid);
                        if (mounted) {
                          setState(() {
                            _followingUid = null;
                            widget.followingIds.add(uid);
                          });
                        }
                      },
                      child: isFollowing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4CAF50)))
                          : const Text('Follow Back', style: TextStyle(color: Color(0xFF4CAF50))),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
