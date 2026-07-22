import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/utils/user_activity_stats.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../achievements/domain/achievements_cubit.dart';

class ComparePage extends StatefulWidget {
  final String userId;
  const ComparePage({super.key, required this.userId});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  Map<String, dynamic>? _otherProfile;
  Map<String, dynamic>? _myStats;
  Map<String, dynamic>? _otherStats;
  List<Map<String, dynamic>> _commonContent = [];
  List<Achievement> _myBadges = [];
  List<Achievement> _otherBadges = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _myLevel = 1;
  int _otherLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final currentUserId = authState.user.id;
    final supabase = context.read<SupabaseService>();
    final achCubit = context.read<AchievementsCubit>();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        supabase.getProfile(widget.userId),
        supabase.getWatchHistory(userId: currentUserId),
        supabase.getWatchHistory(userId: widget.userId),
        supabase.getCommonContent(currentUserId, widget.userId),
      ]);

      final otherProfile = results[0] as Map<String, dynamic>?;
      final myHistory = List<Map<String, dynamic>>.from(results[1] as List);
      final otherHistory = List<Map<String, dynamic>>.from(results[2] as List);
      final commonContent = List<Map<String, dynamic>>.from(results[3] as List);

      final myActivity = UserActivityStats.fromHistory(myHistory);
      final otherActivity = UserActivityStats.fromHistory(otherHistory);
      final myStats = myActivity.toSummaryMap();
      final otherStats = otherActivity.toSummaryMap();

      List<Achievement> myBadges = [];
      List<Achievement> otherBadges = [];
      var myLevel = 1;
      var otherLevel = 1;

      final achState = achCubit.state;
      if (achState is AchievementsLoaded) {
        myBadges = achState.achievements.where((a) => a.isUnlocked).toList()
          ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
        myLevel = achState.level;
      } else {
        try {
          final myAch = await achCubit.calculateForUser(currentUserId);
          myBadges = myAch.achievements.where((a) => a.isUnlocked).toList()
            ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
          myLevel = myAch.level;
        } catch (_) {}
      }

      try {
        final otherAch = await achCubit.calculateForUser(widget.userId);
        otherBadges = otherAch.achievements.where((a) => a.isUnlocked).toList()
          ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
        otherLevel = otherAch.level;
      } catch (_) {
        otherBadges = [];
        otherLevel = 1;
      }

      if (mounted) {
        setState(() {
          _otherProfile = otherProfile;
          _myStats = myStats;
          _otherStats = otherStats;
          _commonContent = commonContent;
          _myBadges = myBadges;
          _otherBadges = otherBadges;
          _myLevel = myLevel;
          _otherLevel = otherLevel;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _hasError
                ? SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text('Failed to load comparison', style: TextStyle(color: AppColors.text(context))),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                          TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                        ],
                      ),
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildLevelComparison(),
                          const SizedBox(height: 20),
                          _buildStatsComparison(),
                          const SizedBox(height: 20),
                          _buildBadgesComparison(),
                          const SizedBox(height: 20),
                          _buildCommonContent(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context)),
          ),
          Expanded(
            child: Text(
              'Compare',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLevelComparison() {
    final otherName = _otherProfile?['username'] as String? ?? 'User';
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Expanded(child: _levelCard('You', _myLevel, AppColors.electricPurple)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.compare_arrows_rounded, color: AppColors.textMuted(context)),
          ),
          Expanded(child: _levelCard(otherName, _otherLevel, const Color(0xFF00B4D8))),
        ],
      ),
    );
  }

  Widget _levelCard(String label, int level, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
          ),
          child: Center(
            child: Text('$level', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 6),
        Text('Level', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsComparison() {
    final my = _myStats ?? {};
    final other = _otherStats ?? {};
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stats', style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _statRow('Shows', my['totalShows'] ?? 0, other['totalShows'] ?? 0),
          _statRow('Movies', my['totalMovies'] ?? 0, other['totalMovies'] ?? 0),
          _statRow('Episodes', my['totalEpisodes'] ?? 0, other['totalEpisodes'] ?? 0),
          _statRow('Hours', my['totalHours'] ?? 0, other['totalHours'] ?? 0),
        ],
      ),
    );
  }

  Widget _statRow(String label, int mine, int theirs) {
    final winMine = mine > theirs;
    final winTheirs = theirs > mine;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '$mine',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: winMine ? AppColors.electricPurple : AppColors.text(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$theirs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: winTheirs ? const Color(0xFF00B4D8) : AppColors.text(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesComparison() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Achievements', style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You · ${_myBadges.length}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
          const SizedBox(height: 8),
          _badgeScroll(_myBadges),
          const SizedBox(height: 16),
          Text(
            '${_otherProfile?['username'] ?? 'User'} · ${_otherBadges.length}',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          _badgeScroll(_otherBadges),
        ],
      ),
    );
  }

  Widget _badgeScroll(List<Achievement> badges) {
    if (badges.isEmpty) {
      return Text('No achievements yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13));
    }
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final badge = badges[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badge.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badge.icon, color: badge.color, size: 13),
                const SizedBox(width: 5),
                Text(badge.title, style: TextStyle(color: badge.color, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommonContent() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In common · ${_commonContent.length}',
            style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_commonContent.isEmpty)
            Text('No shared watch history yet', style: TextStyle(color: AppColors.textMuted(context)))
          else
            ..._commonContent.take(20).map((item) {
              final title = item['title'] as String? ?? 'Unknown';
              final poster = item['poster_path'] as String?;
              final tmdbId = item['tmdb_id'];
              final mediaType = item['media_type'] as String? ?? 'tv';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    if (tmdbId == null) return;
                    context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId');
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: poster != null && poster.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: AppConfig.getImageUrl(poster, size: 'w92'),
                                width: 40,
                                height: 56,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 40,
                                  height: 56,
                                  color: AppColors.cardBg(context),
                                  child: const Icon(Icons.movie, size: 18),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 56,
                                color: AppColors.cardBg(context),
                                child: const Icon(Icons.movie, size: 18),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
