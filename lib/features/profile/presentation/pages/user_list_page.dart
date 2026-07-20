import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/tmdb_service.dart';

class UserListPage extends StatefulWidget {
  final String userId;
  final String listType; // 'watchlist', 'favorites', 'history'

  const UserListPage({super.key, required this.userId, required this.listType});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<Map<String, dynamic>> _groupedHistory = [];
  bool _isLoading = true;
  String _username = 'User';
  String _filter = 'all';
  String _mediaType = 'all';
  final ScrollController _scrollController = ScrollController();
  int _displayCount = 18;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_displayCount < _filteredItems.length) {
        setState(() {
          _displayCount = (_displayCount + 12).clamp(0, _filteredItems.length);
        });
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> items = List.from(_items);

    // Filter by media type
    if (_mediaType == 'tv') {
      items = items.where((i) => i['media_type'] == 'tv').toList();
    } else if (_mediaType == 'movie') {
      items = items.where((i) => i['media_type'] == 'movie').toList();
    }

    // Filter by status (only for watchlist)
    if (widget.listType == 'watchlist' && _filter != 'all') {
      items = items.where((i) => i['status'] == _filter).toList();
    }

    setState(() {
      _filteredItems = items;
      _displayCount = 18;
    });
  }

  Future<void> _loadData() async {
    final supabase = context.read<SupabaseService>();

    try {
      final results = await Future.wait([
        supabase.getProfile(widget.userId),
        _fetchItems(supabase),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final items = results[1] as List<Map<String, dynamic>>;

      await _fetchMissingTitles(items);

      final grouped = widget.listType == 'history' ? _groupHistoryItems(items) : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _username = profile?['username'] ?? 'User';
          _items = items;
          _filteredItems = items;
          _groupedHistory = grouped;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _groupHistoryItems(List<Map<String, dynamic>> history) {
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

      final latestWatched = group['latest_watched_at'] as DateTime;
      if (watchedAt.isAfter(latestWatched)) {
        group['latest_watched_at'] = watchedAt;
        group['latest_season'] = seasonNumber;
        group['latest_episode'] = episodeNumber;
      }
    }

    final result = grouped.values.toList().cast<Map<String, dynamic>>();
    result.sort((a, b) => (b['latest_watched_at'] as DateTime).compareTo(a['latest_watched_at'] as DateTime));
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchItems(SupabaseService supabase) async {
    switch (widget.listType) {
      case 'watchlist':
        return await supabase.getWatchlist(userId: widget.userId);
      case 'favorites':
        return await supabase.getFavorites(userId: widget.userId);
      case 'history':
        return await supabase.getWatchHistory(userId: widget.userId);
      default:
        return [];
    }
  }

  Future<void> _fetchMissingTitles(List<Map<String, dynamic>> items) async {
    final tmdb = context.read<TmdbService>();
    final needFetch = items.where((i) => i['title'] == null || (i['title'] as String).isEmpty).toList();
    if (needFetch.isEmpty) return;

    final futures = needFetch.map((item) async {
      try {
        final tmdbId = item['tmdb_id'] as int?;
        if (tmdbId == null) return;
        final mediaType = item['media_type'] as String? ?? 'tv';
        if (mediaType == 'tv') {
          final data = await tmdb.getShowDetails(tmdbId).timeout(const Duration(seconds: 5));
          item['title'] = data['name'];
          item['poster_path'] = item['poster_path'] ?? data['poster_path'];
          item['vote_average'] = data['vote_average'];
        } else {
          final data = await tmdb.getMovieDetails(tmdbId).timeout(const Duration(seconds: 5));
          item['title'] = data['title'];
          item['poster_path'] = item['poster_path'] ?? data['poster_path'];
          item['vote_average'] = data['vote_average'];
        }
      } catch (e) {
        // Don't set 'Unknown' — leave null so it can be retried next load
      }
    }).toList();

    await Future.wait(futures);
  }

  String _getTitle() {
    switch (widget.listType) {
      case 'watchlist':
        return '$_username\'s Watchlist';
      case 'favorites':
        return '$_username\'s Favorites';
      case 'history':
        return '$_username\'s Watch History';
      default:
        return 'List';
    }
  }

  IconData _getIcon() {
    switch (widget.listType) {
      case 'watchlist':
        return Icons.bookmark_rounded;
      case 'favorites':
        return Icons.favorite_rounded;
      case 'history':
        return Icons.history_rounded;
      default:
        return Icons.list;
    }
  }

  Color _getColor() {
    switch (widget.listType) {
      case 'watchlist':
        return const Color(0xFF6C63FF);
      case 'favorites':
        return const Color(0xFFE50914);
      case 'history':
        return const Color(0xFF00CC6A);
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'watching':
        return const Color(0xFF00D4FF);
      case 'completed':
        return const Color(0xFF00FF88);
      case 'watchlist':
        return const Color(0xFF6C63FF);
      case 'up_to_date':
        return const Color(0xFFFFD93D);
      case 'stopped':
        return const Color(0xFFFF4757);
      default:
        return AppColors.textMuted(context);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'watching':
        return 'Watching';
      case 'completed':
        return 'Completed';
      case 'watchlist':
        return 'Plan to Watch';
      case 'up_to_date':
        return 'Up to Date';
      case 'stopped':
        return 'Stopped';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    if (widget.listType == 'watchlist') ...[
                      _buildMediaTypeTabs(),
                      _buildStatusFilters(),
                    ],
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getTitle(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                Text('${_filteredItems.length} items', style: TextStyle(fontSize: 12, color: AppColors.textMuted(context))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getIcon(), color: _getColor(), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildMediaTypeTab('All', 'all', Icons.list_rounded),
          const SizedBox(width: 8),
          _buildMediaTypeTab('Shows', 'tv', Icons.tv_rounded),
          const SizedBox(width: 8),
          _buildMediaTypeTab('Movies', 'movie', Icons.movie_rounded),
        ],
      ),
    );
  }

  Widget _buildMediaTypeTab(String label, String value, IconData icon) {
    final isSelected = _mediaType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _mediaType = value);
          _applyFilters();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.textMuted(context), size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', 'all'),
          _buildFilterChip('Watching', 'watching'),
          _buildFilterChip('Completed', 'completed'),
          _buildFilterChip('Plan to Watch', 'watchlist'),
          _buildFilterChip('Up to Date', 'up_to_date'),
          _buildFilterChip('Stopped', 'stopped'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _filter = value);
        _applyFilters();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
      ),
    );
  }

  Widget _buildContent() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIcon(), size: 60, color: AppColors.textMuted(context)),
            const SizedBox(height: 16),
            Text('No items yet', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
          ],
        ),
      );
    }

    if (widget.listType == 'history') {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: _buildGroupedHistoryList(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _buildDetailsGrid(),
    );
  }

  Widget _buildDetailsGrid() {
    final displayItems = _filteredItems.take(_displayCount).toList();

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        return _buildDetailGridCard(item);
      },
    );
  }

  Widget _buildDetailGridCard(Map<String, dynamic> item) {
    final tmdbId = item['tmdb_id'];
    final mediaType = item['media_type'] ?? 'tv';
    final posterPath = item['poster_path'] as String?;
    final title = item['title'] ?? 'Unknown';
    final rating = (item['vote_average'] as num?)?.toDouble() ?? 0.0;
    final status = item['status'] as String?;
    final addedAt = item['added_at'] != null ? DateTime.tryParse(item['added_at']) : null;

    return GestureDetector(
      onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Poster
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: posterPath != null && posterPath.toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.getImageUrl(posterPath, size: 'w300'),
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
                // Rating badge (top-left)
                if (rating > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 12),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                // Status badge (bottom)
                if (status != null && widget.listType == 'watchlist')
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, _getStatusColor(status).withValues(alpha: 0.9)],
                        ),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (addedAt != null)
            Text(
              timeago.format(addedAt),
              style: TextStyle(color: AppColors.textMuted(context), fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _groupedHistory.length,
      itemBuilder: (context, index) {
        final item = _groupedHistory[index];
        final tmdbId = item['tmdb_id'];
        final mediaType = item['media_type'] ?? 'tv';
        final posterPath = item['poster_path'];
        final title = item['title'] ?? 'Unknown';
        final episodeCount = item['episode_count'] ?? 0;
        final latestSeason = item['latest_season'];
        final latestEpisode = item['latest_episode'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
            child: GlassContainer(
              padding: const EdgeInsets.all(12),
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
                      child: posterPath != null && posterPath.toString().isNotEmpty
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
                        Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        if (mediaType == 'tv' && latestSeason != null && latestEpisode != null)
                          Text('S$latestSeason E$latestEpisode', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                        const SizedBox(height: 4),
                        if (mediaType == 'tv')
                          Row(
                            children: [
                              Icon(Icons.play_circle_outline, color: AppColors.textMuted(context), size: 14),
                              const SizedBox(width: 4),
                              Text('$episodeCount episodes', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
