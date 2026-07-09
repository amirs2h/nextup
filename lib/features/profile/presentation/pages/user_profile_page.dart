import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../../shared/services/supabase_service.dart';

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
  List<Map<String, dynamic>> _watchHistory = [];
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isOwnProfile = false;
  bool _isPublic = true;

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
      if (!_isOwnProfile) {
        isFollowing = await supabase.isFollowing(currentUserId, widget.userId);
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _isPublic = profile?['is_public'] ?? true;
          _watchlist = watchlist;
          _favorites = favorites;
          _watchHistory = watchHistory;
          _followers = followers;
          _following = following;
          _watchlistCount = watchlist.length;
          _followersCount = followers.length;
          _followingCount = following.length;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final supabase = context.read<SupabaseService>();
    final currentUserId = authState.user.id;

    final wasFollowing = _isFollowing;
    setState(() {
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
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          Text('User not found', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final username = _profile!['username'] ?? 'User';
    final bio = _profile!['bio'] ?? '';
    final avatarUrl = _profile!['avatar_url'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
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
            const SizedBox(height: 24),
            _buildAvatar(username, avatarUrl),
            const SizedBox(height: 16),
            Text(username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(bio, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            _buildStats(),
            const SizedBox(height: 24),
            if (!_isOwnProfile)
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  text: _isFollowing ? 'Following' : 'Follow',
                  icon: _isFollowing ? Icons.check : Icons.person_add,
                  onPressed: _toggleFollow,
                  gradient: _isFollowing
                      ? LinearGradient(colors: [AppColors.cardBg(context), AppColors.cardBg(context)])
                      : null,
                ),
              ),
            if (_isOwnProfile) ...[
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildContentLinks(),
            ],
            if (!_isOwnProfile && !_isPublic) ...[
              const SizedBox(height: 24),
              GlassContainer(
                padding: const EdgeInsets.all(20),
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
            ],
            if (!_isOwnProfile && _isPublic) ...[
              if (_watchlist.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildWatchlistSection(),
              ],
              if (_favorites.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildFavoritesSection(),
              ],
              if (_watchHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildWatchHistorySection(),
              ],
            ],
            if (_isOwnProfile) ...[
              if (_watchlist.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildWatchlistSection(),
              ],
              if (_favorites.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildFavoritesSection(),
              ],
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String username, String? avatarUrl) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: avatarUrl != null
          ? ClipOval(child: CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)))))
          : Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40))),
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
        GlassContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              final username = _profile!['username'] ?? 'User';
              Share.share('Check out $username\'s profile on NextUp!');
            },
            child: Icon(Icons.share, color: AppColors.text(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildContentLinks() {
    return Column(
      children: [
        _buildContentCard(icon: Icons.bookmark_outline, title: 'My Watchlist', subtitle: 'Shows and movies to watch', onTap: () => context.go('/watchlist')),
        _buildContentCard(icon: Icons.favorite_outline, title: 'Favorites', subtitle: 'Your favorite shows and movies', onTap: () => context.push('/favorites')),
        _buildContentCard(icon: Icons.history, title: 'Watch History', subtitle: 'Shows and movies you\'ve watched', onTap: () => context.push('/watch-history')),
        _buildContentCard(icon: Icons.bar_chart_outlined, title: 'Statistics', subtitle: 'Your watching stats', onTap: () => context.push('/stats')),
        _buildContentCard(icon: Icons.emoji_events_outlined, title: 'Achievements', subtitle: 'Your badges and milestones', onTap: () => context.push('/achievements')),
        _buildContentCard(icon: Icons.people_outline, title: 'Activity', subtitle: 'What your friends are watching', onTap: () => context.push('/activity')),
      ],
    );
  }

  Widget _buildContentCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.icon(context), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Watchlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _watchlist.length,
            itemBuilder: (context, index) {
              final item = _watchlist[index];
              final tmdbId = item['tmdb_id'];
              final mediaType = item['media_type'] ?? 'tv';
              final posterPath = item['poster_path'];
              final title = item['title'] ?? 'Unknown';

              return GestureDetector(
                onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.cardBg(context)),
                        child: posterPath != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: AppConfig.getImageUrl(posterPath, size: 'w154'), fit: BoxFit.cover, errorWidget: (c, u, e) => Center(child: Icon(Icons.movie, color: AppColors.textMuted(context)))))
                            : Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: AppColors.text(context), size: 20),
            const SizedBox(width: 8),
            Text('Favorites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final item = _favorites[index];
              final tmdbId = item['tmdb_id'];
              final mediaType = item['media_type'] ?? 'tv';
              final posterPath = item['poster_path'];
              final title = item['title'] ?? 'Unknown';

              return GestureDetector(
                onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.cardBg(context)),
                        child: posterPath != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: AppConfig.getImageUrl(posterPath, size: 'w154'), fit: BoxFit.cover, errorWidget: (c, u, e) => Center(child: Icon(Icons.movie, color: AppColors.textMuted(context)))))
                            : Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: AppColors.text(context), size: 20),
            const SizedBox(width: 8),
            Text('Watch History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _watchHistory.length,
            itemBuilder: (context, index) {
              final item = _watchHistory[index];
              final tmdbId = item['tmdb_id'];
              final mediaType = item['media_type'] ?? 'tv';
              final posterPath = item['poster_path'];
              final title = item['title'] ?? 'Unknown';

              return GestureDetector(
                onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.cardBg(context)),
                        child: posterPath != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: AppConfig.getImageUrl(posterPath, size: 'w154'), fit: BoxFit.cover, errorWidget: (c, u, e) => Center(child: Icon(Icons.movie, color: AppColors.textMuted(context)))))
                            : Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
