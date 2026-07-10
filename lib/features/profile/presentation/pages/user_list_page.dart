import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  bool _isLoading = true;
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final supabase = context.read<SupabaseService>();

    try {
      // Load profile and items in parallel
      final results = await Future.wait([
        supabase.getProfile(widget.userId),
        _fetchItems(supabase),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final items = results[1] as List<Map<String, dynamic>>;

      // Fetch missing titles
      await _fetchMissingTitles(items);

      if (mounted) {
        setState(() {
          _username = profile?['username'] ?? 'User';
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
    for (final item in items) {
      if (item['title'] == null || (item['title'] as String).isEmpty) {
        try {
          final tmdbId = item['tmdb_id'] as int;
          final mediaType = item['media_type'] as String? ?? 'tv';
          if (mediaType == 'tv') {
            final data = await tmdb.getShowDetails(tmdbId);
            item['title'] = data['name'] ?? 'Unknown';
            item['poster_path'] = item['poster_path'] ?? data['poster_path'];
          } else {
            final data = await tmdb.getMovieDetails(tmdbId);
            item['title'] = data['title'] ?? 'Unknown';
            item['poster_path'] = item['poster_path'] ?? data['poster_path'];
          }
        } catch (e) {
          item['title'] = 'Unknown';
        }
      }
    }
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
                    // Header
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
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getColor().withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(_getIcon(), color: _getColor(), size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_getTitle(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getColor().withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${_items.length}', style: TextStyle(color: _getColor(), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Content
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getIcon(), size: 60, color: AppColors.textMuted(context)),
                                  const SizedBox(height: 16),
                                  Text('No items yet', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final tmdbId = item['tmdb_id'];
                                  final mediaType = item['media_type'] ?? 'tv';
                                  final posterPath = item['poster_path'];
                                  final title = item['title'] ?? 'Unknown';

                                  return GestureDetector(
                                    onTap: () => context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId'),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Container(
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
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          style: TextStyle(color: AppColors.text(context), fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
