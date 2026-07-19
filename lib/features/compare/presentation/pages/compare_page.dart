import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../achievements/domain/achievements_cubit.dart';
import '../../../profile/domain/profile_cubit.dart';

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

    try {
      // Load all data in parallel
      final results = await Future.wait([
        supabase.getProfile(widget.userId),
        supabase.getWatchHistory(userId: currentUserId),
        supabase.getWatchHistory(userId: widget.userId),
        supabase.getCommonContent(currentUserId, widget.userId),
      ]);

      final otherProfile = results[0] as Map<String, dynamic>?;
      final myHistory = results[1] as List<Map<String, dynamic>>;
      final otherHistory = results[2] as List<Map<String, dynamic>>;
      final commonContent = results[3] as List<Map<String, dynamic>>;

      // Compute stats
      final myStats = _computeStats(myHistory);
      final otherStats = _computeStats(otherHistory);

      // Get achievements for both users
      final achState = context.read<AchievementsCubit>().state;
      List<Achievement> myBadges = [];
      List<Achievement> otherBadges = [];
      int myLevel = 1;
      int otherLevel = 1;

      if (achState is AchievementsLoaded) {
        myBadges = achState.achievements.where((a) => a.isUnlocked).toList()
          ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
        myLevel = achState.level;
      }

      // For other user, we can't easily compute achievements without loading their data
      // For now, we'll show N/A for their badges
      otherBadges = [];
      otherLevel = 0;

      if (mounted) {
        setState(() {
          _otherProfile = otherProfile;
          _myStats = myStats;
          _otherStats = otherStats;
          _commonContent = commonContent;
          _myBadges = myBadges.take(3).toList();
          _otherBadges = otherBadges.take(3).toList();
          _myLevel = myLevel;
          _otherLevel = otherLevel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _computeStats(List<Map<String, dynamic>> history) {
    int totalShows = 0;
    int totalMovies = 0;
    int totalEpisodes = 0;
    Set<String> showIds = {};
    Set<String> movieIds = {};

    for (final item in history) {
      final tmdbId = item['tmdb_id']?.toString() ?? '';
      final mediaType = item['media_type'] ?? 'tv';

      if (mediaType == 'tv') {
        showIds.add(tmdbId);
        totalEpisodes++;
      } else {
        movieIds.add(tmdbId);
      }
    }

    totalShows = showIds.length;
    totalMovies = movieIds.length;
    final totalHours = (totalEpisodes * 45 + totalMovies * 120) / 60;

    return {
      'totalShows': totalShows,
      'totalMovies': totalMovies,
      'totalEpisodes': totalEpisodes,
      'totalHours': totalHours.round(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildStatComparison(),
                      const SizedBox(height: 20),
                      _buildCommonContent(),
                      const SizedBox(height: 20),
                      _buildBadgeComparison(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final authState = context.read<AuthCubit>().state;
    final myName = authState is AuthAuthenticated ? (authState.profile?['username'] ?? 'You') : 'You';
    final otherName = _otherProfile?['username'] ?? 'User';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg(context),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Text('Stats Comparison', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 4),
                Text('$myName vs $otherName', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatComparison() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.electricPurple, size: 18),
              const SizedBox(width: 8),
              Text('Watch Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Shows', _myStats?['totalShows'] ?? 0, _otherStats?['totalShows'] ?? 0),
          _buildStatRow('Movies', _myStats?['totalMovies'] ?? 0, _otherStats?['totalMovies'] ?? 0),
          _buildStatRow('Episodes', _myStats?['totalEpisodes'] ?? 0, _otherStats?['totalEpisodes'] ?? 0),
          _buildStatRow('Hours', _myStats?['totalHours'] ?? 0, _otherStats?['totalHours'] ?? 0, suffix: 'h'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int myValue, int otherValue, {String suffix = ''}) {
    final authState = context.read<AuthCubit>().state;
    final myName = authState is AuthAuthenticated ? (authState.profile?['username'] ?? 'You') : 'You';
    final otherName = _otherProfile?['username'] ?? 'User';
    final max = [myValue, otherValue].reduce((a, b) => a > b ? a : b);
    final myPct = max > 0 ? myValue / max : 0.0;
    final otherPct = max > 0 ? otherValue / max : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('${myValue}$suffix', style: TextStyle(color: AppColors.electricPurple, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: myPct,
                    minHeight: 8,
                    backgroundColor: AppColors.cardBg(context),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.electricPurple),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                child: Text(myName[0].toUpperCase(), style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('${otherValue}$suffix', style: TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: otherPct,
                    minHeight: 8,
                    backgroundColor: AppColors.cardBg(context),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                child: Text(otherName[0].toUpperCase(), style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommonContent() {
    if (_commonContent.isEmpty) return const SizedBox();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text('You both watched', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_commonContent.length}', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _commonContent.length,
              itemBuilder: (context, index) {
                final item = _commonContent[index];
                final tmdbId = item['tmdb_id'];
                final mediaType = item['media_type'] ?? 'tv';
                final posterPath = item['poster_path'] as String?;
                final title = item['title'] ?? 'Unknown';

                return GestureDetector(
                  onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: posterPath != null && posterPath.toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: AppConfig.getImageUrl(posterPath, size: 'w154'),
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => Container(
                                      color: AppColors.cardBg(context),
                                      child: Icon(Icons.movie, color: AppColors.textMuted(context)),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.cardBg(context),
                                    child: Icon(Icons.movie, color: AppColors.textMuted(context)),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: TextStyle(color: AppColors.text(context), fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeComparison() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text('Top Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
          const SizedBox(height: 16),
          // My badges
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text('Level $_myLevel', style: TextStyle(color: AppColors.electricPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (ctx) {
                        final s = context.read<AuthCubit>().state;
                        final n = s is AuthAuthenticated ? (s.profile?['username'] ?? 'You') : 'You';
                        return Text(n, style: TextStyle(color: AppColors.text(context), fontSize: 11));
                      },
                    ),
                  ],
                ),
              ),
              ..._myBadges.map((badge) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.color.withValues(alpha: 0.15),
                    border: Border.all(color: badge.rarityColor.withValues(alpha: 0.5), width: 2),
                    boxShadow: [BoxShadow(color: badge.rarityColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(badge.icon, color: badge.color, size: 16),
                      const SizedBox(height: 2),
                      Text(
                        badge.rarity == AchievementRarity.legendary ? '⭐' : badge.rarity == AchievementRarity.epic ? '💜' : badge.rarity == AchievementRarity.rare ? '💙' : '🤍',
                        style: const TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 12),
          // Other user's badges
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text(_otherLevel > 0 ? 'Level $_otherLevel' : 'N/A', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_otherProfile?['username'] ?? 'User', style: TextStyle(color: AppColors.text(context), fontSize: 11)),
                  ],
                ),
              ),
              if (_otherBadges.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('No badge data available', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                )
              else
                ..._otherBadges.map((badge) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badge.color.withValues(alpha: 0.15),
                      border: Border.all(color: badge.rarityColor.withValues(alpha: 0.5), width: 2),
                      boxShadow: [BoxShadow(color: badge.rarityColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(badge.icon, color: badge.color, size: 16),
                        const SizedBox(height: 2),
                        Text(
                          badge.rarity == AchievementRarity.legendary ? '⭐' : badge.rarity == AchievementRarity.epic ? '💜' : badge.rarity == AchievementRarity.rare ? '💙' : '🤍',
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                )),
            ],
          ),
        ],
      ),
    );
  }
}
