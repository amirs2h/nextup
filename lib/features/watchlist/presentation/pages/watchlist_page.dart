import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/watchlist_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../shared/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WatchlistPageView();
  }
}

class _WatchlistPageView extends StatefulWidget {
  const _WatchlistPageView();

  @override
  State<_WatchlistPageView> createState() => _WatchlistPageViewState();
}

class _WatchlistPageViewState extends State<_WatchlistPageView> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  void _loadWatchlist() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<WatchlistCubit>().loadWatchlist(filter: _filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthUnauthenticated) {
            return _buildLoginPrompt(context);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildFilterTabs(context),
              Expanded(child: _buildContent(context)),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline_rounded, size: 60, color: AppColors.textMuted(context)),
          const SizedBox(height: 16),
          Text('Please login to view your watchlist', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Login')),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('Watchlist', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const Spacer(),
          GestureDetector(
            onTap: _loadWatchlist,
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.refresh_rounded, color: AppColors.text(context), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(context, 'All', 'all'),
          _buildFilterChip(context, 'Watching', 'watching'),
          _buildFilterChip(context, 'Completed', 'completed'),
          _buildFilterChip(context, 'Up to Date', 'up_to_date'),
          _buildFilterChip(context, 'Watchlist', 'watchlist'),
          _buildFilterChip(context, 'Stopped', 'stopped'),
          _buildFilterChip(context, 'Shows', 'shows'),
          _buildFilterChip(context, 'Movies', 'movies'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        context.read<WatchlistCubit>().setFilter(value);
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

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, state) {
        if (state is WatchlistLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is WatchlistError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadWatchlist, child: const Text('Retry')),
              ],
            ),
          );
        }

        if (state is WatchlistLoaded) {
          final showItems = state.showItems;
          final movieItems = state.movieItems;

          if (showItems.isEmpty && movieItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline_rounded, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('Your watchlist is empty', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Add shows and movies to watch later', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Find Shows'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (showItems.isNotEmpty) ...[
                Text('Shows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 12),
                ...showItems.map((item) => _buildItemCard(context, item)),
                const SizedBox(height: 20),
              ],
              if (movieItems.isNotEmpty) ...[
                Text('Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 12),
                ...movieItems.map((item) => _buildItemCard(context, item)),
              ],
              const SizedBox(height: 100),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildItemCard(BuildContext context, WatchlistItem item) {
    final isShow = item.mediaType == 'tv';
    final name = isShow ? (item.model as ShowModel).name : (item.model as MovieModel).title;
    final rating = isShow ? (item.model as ShowModel).voteAverage : (item.model as MovieModel).voteAverage;
    final posterUrl = isShow ? (item.model as ShowModel).posterUrl : (item.model as MovieModel).posterUrl;
    final id = isShow ? (item.model as ShowModel).id : (item.model as MovieModel).id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push(isShow ? '/show/$id' : '/movie/$id'),
        onLongPress: () => _showStatusPicker(context, id, item.mediaType, item.status),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 85,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posterUrl != null
                    ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Icon(Icons.movie_rounded, color: AppColors.textMuted(context)))
                    : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie_rounded, color: AppColors.textMuted(context))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context))),
                      const SizedBox(width: 12),
                      _buildStatusBadge(context, item.status, id, item.mediaType),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppColors.surface(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Remove from Watchlist'),
                    content: Text('Remove "${item.mediaType == 'tv' ? (item.model as ShowModel).name : (item.model as MovieModel).title}" from your watchlist?'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface(context),
                          foregroundColor: AppColors.text(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.read<WatchlistCubit>().removeFromWatchlist(id, item.mediaType);
                        },
                        child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, int tmdbId, String mediaType) {
    Color color;
    String label;
    switch (status) {
      case 'watching':
        color = AppColors.info;
        label = 'Watching';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Completed';
        break;
      case 'up_to_date':
        color = AppColors.warning;
        label = 'Up to Date';
        break;
      case 'stopped':
        color = AppColors.error;
        label = 'Stopped';
        break;
      default:
        color = AppColors.textMuted(context);
        label = 'Watchlist';
    }

    return GestureDetector(
      onTap: () => _showStatusPicker(context, tmdbId, mediaType, status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, int tmdbId, String mediaType, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        children: [
          _buildStatusOption(ctx, 'Watchlist', 'watchlist', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, 'Watching', 'watching', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, 'Completed', 'completed', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, 'Up to Date', 'up_to_date', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, 'Stopped', 'stopped', currentStatus, tmdbId, mediaType),
        ],
      ),
    );
  }

  Widget _buildStatusOption(BuildContext ctx, String label, String value, String current, int tmdbId, String mediaType) {
    final isSelected = value == current;
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(ctx);
        if (tmdbId > 0 && mediaType.isNotEmpty) {
          context.read<WatchlistCubit>().updateStatus(tmdbId, mediaType, value);
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.text(context), fontSize: 16)),
          ),
          if (isSelected) const Icon(Icons.check, color: AppColors.primary),
        ],
      ),
    );
  }
}
