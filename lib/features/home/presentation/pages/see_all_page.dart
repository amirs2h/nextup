import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../shared/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';

class SeeAllPage extends StatefulWidget {
  final String title;
  final String type; // 'trending_shows', 'trending_movies', 'top_rated'

  const SeeAllPage({super.key, required this.title, required this.type});

  @override
  State<SeeAllPage> createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  final TmdbService _tmdbService = TmdbService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      Map<String, dynamic> data;

      switch (widget.type) {
        case 'trending_shows':
          data = await _tmdbService.getTrendingShows(page: _page);
          break;
        case 'trending_movies':
          data = await _tmdbService.getTrendingMovies(page: _page);
          break;
        case 'top_rated':
          data = await _tmdbService.discoverShows(sortBy: 'vote_average.desc', page: _page);
          break;
        default:
          data = await _tmdbService.getTrendingShows(page: _page);
      }

      final results = data['results'] as List? ?? [];
      final newItems = widget.type.contains('movie')
          ? results.map((json) => MovieModel.fromJson(json)).toList()
          : results.map((json) => ShowModel.fromJson(json)).toList();

      setState(() {
        _items.addAll(newItems);
        _isLoading = false;
        _hasMore = results.length >= 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg(context),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(widget.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    if (_items.isEmpty) {
      return Center(
        child: Text('No items found', style: TextStyle(color: AppColors.textMuted(context))),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && _hasMore && !_isLoading) {
          _page++;
          _loadItems();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
          }

          final item = _items[index];
          final String title;
          final String? posterUrl;
          final int id;
          final double rating;

          if (item is ShowModel) {
            title = item.name;
            posterUrl = item.posterUrl;
            id = item.id;
            rating = item.voteAverage;
          } else if (item is MovieModel) {
            title = item.title;
            posterUrl = item.posterUrl;
            id = item.id;
            rating = item.voteAverage;
          } else {
            return const SizedBox();
          }

          return GestureDetector(
            onTap: () => context.push(widget.type.contains('movie') ? '/movie/$id' : '/show/$id'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: posterUrl != null
                          ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))))
                          : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 12), const SizedBox(width: 2), Text(rating.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11))]),
              ],
            ),
          );
        },
      ),
    );
  }
}
