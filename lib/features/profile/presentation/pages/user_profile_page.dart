import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../achievements/domain/achievements_cubit.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/tmdb_service.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _profile;
  int _followersCount = 0;
  int _followingCount = 0;
  int _watchlistCount = 0;
  List<Map<String, dynamic>> _watchlist = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _groupedWatchHistory = [];
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isOwnProfile = false;
  bool _isPublic = true;
  bool _isTogglingFollow = false;
  bool _isFollowingMe = false;
  List<Map<String, dynamic>> _publicCustomLists = [];
  List<Map<String, dynamic>> _commonSharedLists = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final currentUserId = authState.user.id;
    _isOwnProfile = currentUserId == widget.userId;

    final supabase = context.read<SupabaseService>();

    try {
      final results = await Future.wait([
        supabase.getProfile(widget.userId),
        supabase.getWatchlist(userId: widget.userId),
        supabase.getFavorites(userId: widget.userId),
        supabase.getFollowers(widget.userId),
        supabase.getFollowing(widget.userId),
        supabase.getWatchHistory(userId: widget.userId),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final watchlist = results[1] as List<Map<String, dynamic>>;
      final favorites = results[2] as List<Map<String, dynamic>>;
      final followers = results[3] as List<Map<String, dynamic>>;
      final following = results[4] as List<Map<String, dynamic>>;
      final watchHistory = results[5] as List<Map<String, dynamic>>;

      bool isFollowing = false;
      bool isFollowingMe = false;
      if (!_isOwnProfile) {
        final results2 = await Future.wait([
          supabase.isFollowing(currentUserId, widget.userId),
          supabase.isFollowing(widget.userId, currentUserId),
        ]);
        isFollowing = results2[0] as bool;
        isFollowingMe = results2[1] as bool;
      }

      // Group watch history by tmdb_id
      final groupedHistory = _groupWatchHistory(watchHistory);

      // Show profile immediately — don't wait for missing titles
      if (mounted) {
        setState(() {
          _profile = profile;
          _isPublic = profile?['is_public'] ?? true;
          _watchlist = watchlist;
          _favorites = favorites;
          _groupedWatchHistory = groupedHistory;
          _followers = followers;
          _following = following;
          _watchlistCount = watchlist.length;
          _followersCount = followers.length;
          _followingCount = following.length;
          _isFollowing = isFollowing;
          _isFollowingMe = isFollowingMe;
          _isLoading = false;
        });
      }

      // Load public custom lists + common shared lists in parallel (non-blocking)
      if (!_isOwnProfile && (_isPublic || _isFollowing)) {
        final listResults = await Future.wait([
          supabase.getPublicCustomLists(widget.userId),
          supabase.getCommonSharedLists(widget.userId),
        ]);
        if (mounted) {
          final publicLists = listResults[0] as List<Map<String, dynamic>>;
          final sharedLists = listResults[1] as List<Map<String, dynamic>>;
          if (publicLists.isNotEmpty) setState(() => _publicCustomLists = publicLists);
          if (sharedLists.isNotEmpty) setState(() => _commonSharedLists = sharedLists);
        }
      }

      // Fetch missing titles in parallel, update UI as each completes
      await Future.wait([
        _fetchMissingTitles(watchlist).then((_) {
          if (mounted) setState(() {});
        }),
        _fetchMissingTitles(favorites).then((_) {
          if (mounted) setState(() {});
        }),
        _fetchMissingTitles(watchHistory).then((_) {
          if (mounted) {
            setState(() {
              _groupedWatchHistory = _groupWatchHistory(watchHistory);
            });
          }
        }),
      ]);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMissingTitles(List<Map<String, dynamic>> items) async {
    final tmdb = context.read<TmdbService>();
    final itemsNeedingFetch = items.where((item) =>
        item['title'] == null || (item['title'] as String? ?? '').isEmpty).take(20).toList();

    if (itemsNeedingFetch.isEmpty) return;

    final futures = itemsNeedingFetch.map((item) async {
      try {
        final tmdbId = item['tmdb_id'] as int?;
        if (tmdbId == null) return;
        final mediaType = item['media_type'] as String? ?? 'tv';
        if (mediaType == 'tv') {
          final data = await tmdb.getShowDetails(tmdbId).timeout(const Duration(seconds: 8));
          item['title'] = data['name'];
          item['poster_path'] = item['poster_path'] ?? data['poster_path'];
        } else {
          final data = await tmdb.getMovieDetails(tmdbId).timeout(const Duration(seconds: 8));
          item['title'] = data['title'];
          item['poster_path'] = item['poster_path'] ?? data['poster_path'];
        }
      } catch (e) {
        // Don't set 'Unknown' — leave as null so it can be retried on next load
      }
    }).toList();

    await Future.wait(futures);
  }

  List<Map<String, dynamic>> _groupWatchHistory(List<Map<String, dynamic>> history) {
    final Map<int, Map<String, dynamic>> grouped = {};
    
    for (final item in history) {
      final tmdbId = item['tmdb_id'] as int;
      final mediaType = item['media_type'] as String? ?? 'tv';
      final title = item['title'] as String? ?? 'Unknown';
      final posterPath = item['poster_path'] as String?;
      final watchedAt = item['watched_at'] != null ? DateTime.tryParse(item['watched_at']) ?? DateTime.now() : DateTime.now();
      final seasonNumber = item['season_number'] as int?;
      final episodeNumber = item['episode_number'] as int?;

      if (!grouped.containsKey(tmdbId)) {
        grouped[tmdbId] = {
          'tmdb_id': tmdbId,
          'media_type': mediaType,
          'title': title,
          'poster_path': posterPath,
          'episode_count': 0,
          'latest_season': seasonNumber,
          'latest_episode': episodeNumber,
          'latest_watched_at': watchedAt,
        };
      }

      final group = grouped[tmdbId]!;
      group['episode_count'] = (group['episode_count'] as int) + 1;
      
      // Update latest watched
      final latestWatched = group['latest_watched_at'] as DateTime;
      if (watchedAt.isAfter(latestWatched)) {
        group['latest_watched_at'] = watchedAt;
        group['latest_season'] = seasonNumber;
        group['latest_episode'] = episodeNumber;
      }
    }

    final result = grouped.values.toList();
    result.sort((a, b) => (b['latest_watched_at'] as DateTime).compareTo(a['latest_watched_at'] as DateTime));
    return result;
  }

  Future<void> _toggleFollow() async {
    if (_isTogglingFollow) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final supabase = context.read<SupabaseService>();
    final currentUserId = authState.user.id;

    final wasFollowing = _isFollowing;
    HapticFeedback.lightImpact();
    setState(() {
      _isTogglingFollow = true;
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
    });

    try {
      if (_isFollowing) {
        await supabase.followUser(currentUserId, widget.userId);
      } else {
        await supabase.unfollowUser(currentUserId, widget.userId);
      }
    } catch (e) {
      setState(() {
        _isFollowing = wasFollowing;
        _followersCount += wasFollowing ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to update. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  void _showFollowing() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Following', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        children: [
          if (_following.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Not following anyone yet', style: TextStyle(color: AppColors.textMuted(context))),
            )
          else
            ..._following.map((user) {
              final username = user['profiles']?['username'] ?? user['username'] ?? 'User';
              final uid = user['following_id'];
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/user/$uid');
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(username, style: TextStyle(color: AppColors.text(context), fontSize: 16))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showFollowers() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Followers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        children: [
          if (_followers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No followers yet', style: TextStyle(color: AppColors.textMuted(context))),
            )
          else
            ..._followers.map((user) {
              final username = user['profiles']?['username'] ?? user['username'] ?? 'User';
              final uid = user['follower_id'];
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/user/$uid');
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(username, style: TextStyle(color: AppColors.text(context), fontSize: 16))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _profile == null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: _buildContent(),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Could not load profile', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 18)),
            const SizedBox(height: 8),
            Text('Check your internet connection and try again.', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {
              setState(() => _isLoading = true);
              _loadProfile();
            }, child: const Text('Retry')),
            const SizedBox(height: 12),
            TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final username = _profile!['username'] ?? 'User';
    final bio = _profile!['bio'] ?? '';
    final avatarUrl = _profile!['avatar_url'];
    final headerUrl = _profile!['header_image_url'];

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header with back button and optional settings
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(10),
                      borderRadius: BorderRadius.circular(14),
                      child: Icon(Icons.arrow_back, color: AppColors.text(context), size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context)))),
                  if (_isOwnProfile)
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(10),
                        borderRadius: BorderRadius.circular(14),
                        child: Icon(Icons.settings_outlined, color: AppColors.text(context), size: 24),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Header image (like profile_page)
            _buildHeaderImage(headerUrl, avatarUrl, username),
            // Avatar + Name + Bio (always visible)
            Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  _buildAvatar(username, avatarUrl),
                  const SizedBox(height: 12),
                  Text(username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(bio, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  // Level + Badges (only for own profile)
                  if (_isOwnProfile)
                    BlocBuilder<AchievementsCubit, AchievementsState>(
                      builder: (context, achState) {
                        if (achState is! AchievementsLoaded) return const SizedBox();
                        final level = achState.level;
                        final currentXp = achState.currentXp;
                        final xpToNext = achState.xpToNextLevel;
                        final topBadges = achState.achievements.where((a) => a.isUnlocked).toList()
                          ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
                        final displayBadges = topBadges.take(3).toList();

                        if (displayBadges.isEmpty) return const SizedBox();

                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              // Level + XP
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppColors.primaryGradient,
                                      ),
                                      child: Center(child: Text('$level', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Level $level', style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.w600)),
                                        SizedBox(
                                          width: 100,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: xpToNext > 0 ? currentXp / xpToNext : 0,
                                              minHeight: 4,
                                              backgroundColor: AppColors.cardBg(context),
                                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Top 3 Badges
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: displayBadges.map((badge) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: GestureDetector(
                                      onTap: () => context.push('/achievements'),
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: badge.color.withValues(alpha: 0.15),
                                          border: Border.all(color: badge.rarityColor.withValues(alpha: 0.5), width: 2),
                                          boxShadow: [BoxShadow(color: badge.rarityColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(badge.icon, color: badge.color, size: 18),
                                            const SizedBox(height: 2),
                                            Text(
                                              badge.rarity == AchievementRarity.legendary ? '⭐' : badge.rarity == AchievementRarity.epic ? '💜' : badge.rarity == AchievementRarity.rare ? '💙' : '🤍',
                                              style: const TextStyle(fontSize: 8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Stats (always visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStats(),
            ),
            const SizedBox(height: 24),
            // Follow button (only for other users)
            if (!_isOwnProfile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    text: _isTogglingFollow
                        ? 'Loading...'
                        : _isFollowing
                            ? 'Following'
                            : _isFollowingMe
                                ? 'Follow Back'
                                : 'Follow',
                    icon: _isTogglingFollow
                        ? null
                        : _isFollowing
                            ? Icons.check
                            : Icons.person_add,
                    onPressed: _isTogglingFollow ? null : _toggleFollow,
                    gradient: _isFollowing
                        ? const LinearGradient(colors: [Color(0xFF00FF88), Color(0xFF00CC6A)])
                        : null,
                  ),
                ),
              ),
            // Compare button (only for other users)
            if (!_isOwnProfile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/compare/${widget.userId}'),
                    icon: Icon(Icons.compare_arrows_rounded, color: AppColors.electricPurple),
                    label: Text('Compare Stats', style: TextStyle(color: AppColors.electricPurple)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.electricPurple.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            // Own profile action buttons
            if (_isOwnProfile) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActionButtons(),
              ),
            ],
            const SizedBox(height: 24),
            // Content sections
            if (_isPublic || _isOwnProfile || _isFollowing) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (_watchlist.isNotEmpty) ...[
                      _buildSectionHeader('Watchlist', Icons.bookmark_rounded, const Color(0xFF6C63FF),
                        onSeeAll: () => context.push('/user/${widget.userId}/list/watchlist')),
                      const SizedBox(height: 12),
                      _buildMediaCarousel(_watchlist.take(10).toList()),
                      const SizedBox(height: 24),
                    ],
                    if (_favorites.isNotEmpty) ...[
                      _buildSectionHeader('Favorites', Icons.favorite_rounded, const Color(0xFFE50914),
                        onSeeAll: () => context.push('/user/${widget.userId}/list/favorites')),
                      const SizedBox(height: 12),
                      _buildMediaCarousel(_favorites.take(10).toList()),
                      const SizedBox(height: 24),
                    ],
                    if (_groupedWatchHistory.isNotEmpty) ...[
                      _buildSectionHeader('Watch History', Icons.history_rounded, const Color(0xFF00CC6A),
                        onSeeAll: () => context.push('/user/${widget.userId}/list/history')),
                      const SizedBox(height: 12),
                      _buildGroupedHistoryCarousel(_groupedWatchHistory.take(10).toList()),
                      const SizedBox(height: 24),
                    ],
                    if (_publicCustomLists.isNotEmpty) ...[
                      _buildSectionHeader('Public Lists', Icons.list_rounded, const Color(0xFFFFD93D)),
                      const SizedBox(height: 12),
                      ..._publicCustomLists.map((list) {
                        final listId = list['id'] as String?;
                        final name = list['name'] ?? 'Untitled';
                        final desc = list['description'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => context.push('/custom-list/$listId'),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.list_rounded, color: const Color(0xFFFFD93D), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 13)),
                                        if (desc.isNotEmpty)
                                          Text(desc, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: AppColors.textMuted(context), size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                    if (_commonSharedLists.isNotEmpty) ...[
                      _buildSectionHeader('Shared Lists', Icons.people_alt_rounded, const Color(0xFF00B4D8)),
                      const SizedBox(height: 12),
                      ..._commonSharedLists.map((list) {
                        final listId = list['id'] as String?;
                        final name = list['name'] ?? 'Untitled';
                        final desc = list['description'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => context.push('/shared-list/$listId', extra: name),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.people_alt_rounded, color: const Color(0xFF00B4D8), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 13)),
                                        if (desc.isNotEmpty)
                                          Text(desc, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: AppColors.textMuted(context), size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                    if (_watchlist.isEmpty && _favorites.isEmpty && _groupedWatchHistory.isEmpty && _publicCustomLists.isEmpty && _commonSharedLists.isEmpty)
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Icon(Icons.movie_outlined, size: 40, color: AppColors.textMuted(context)),
                            const SizedBox(height: 12),
                            Text('No activity yet', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (!_isPublic && !_isOwnProfile) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Icon(Icons.lock_outline, size: 40, color: AppColors.textMuted(context)),
                      const SizedBox(height: 12),
                      Text('This profile is private', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Follow this user to see their content', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String? headerUrl, String? avatarUrl, String username) {
    // Use header_image_url if available, otherwise show gradient
    // (watchlist backdrop would require fetching TMDB data which is expensive)
    
    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD), Color(0xFFE50914)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: headerUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: headerUrl,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD), Color(0xFFE50914)]),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD), Color(0xFFE50914)]),
                ),
                child: Center(
                  child: Icon(Icons.movie_outlined, size: 50, color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatar(String username, String? avatarUrl) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
        border: Border.all(color: AppColors.background(context), width: 4),
        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: avatarUrl != null
          ? ClipOval(child: CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36)))))
          : Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36))),
    );
  }

  Widget _buildStats() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Watchlist', _watchlistCount),
          Container(width: 1, height: 40, color: AppColors.divider(context)),
          GestureDetector(
            onTap: _showFollowing,
            child: _buildStatItem('Following', _followingCount),
          ),
          Container(width: 1, height: 40, color: AppColors.divider(context)),
          GestureDetector(
            onTap: _showFollowers,
            child: _buildStatItem('Followers', _followersCount),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
      ],
    );
  }

  Widget _buildActionButtons() {
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
            final username = _profile!['username'] ?? 'User';
            Share.share('Check out $username\'s profile on NextUp!');
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

  Widget _buildSectionHeader(String title, IconData icon, Color color, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: color, size: 12),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaCarousel(List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final tmdbId = item['tmdb_id'];
          final mediaType = item['media_type'] ?? 'tv';
          final posterPath = item['poster_path'];
          final title = item['title'] ?? 'Unknown';

          return GestureDetector(
            onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
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
                      child: posterPath != null && posterPath.toString().isNotEmpty
                          ? CachedNetworkImage(imageUrl: AppConfig.getImageUrl(posterPath, size: 'w154'), fit: BoxFit.cover, errorWidget: (c, u, e) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))))
                          : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedHistoryCarousel(List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final tmdbId = item['tmdb_id'];
          final mediaType = item['media_type'] ?? 'tv';
          final posterPath = item['poster_path'];
          final title = item['title'] ?? 'Unknown';
          final episodeCount = item['episode_count'] ?? 0;
          final latestSeason = item['latest_season'];
          final latestEpisode = item['latest_episode'];

          return GestureDetector(
            onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Stack(
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
                          child: posterPath != null && posterPath.toString().isNotEmpty
                              ? CachedNetworkImage(imageUrl: AppConfig.getImageUrl(posterPath, size: 'w154'), fit: BoxFit.cover, errorWidget: (c, u, e) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))))
                              : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                        ),
                      ),
                      // Episode count badge
                      if (mediaType == 'tv' && episodeCount > 1)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$episodeCount eps', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  if (mediaType == 'tv' && latestSeason != null && latestEpisode != null)
                    Text('S$latestSeason E$latestEpisode', style: TextStyle(color: AppColors.textMuted(context), fontSize: 10), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
