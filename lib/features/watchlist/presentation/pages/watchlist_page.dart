import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/localization/app_strings.dart';

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
  String _mediaType = 'all'; // 'all', 'tv', 'movie'

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
              children: [
                _buildHeader(context),
                _buildMediaTypeTabs(context),
                _buildStatusFilters(context),
                Expanded(child: _buildContent(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final s = AppStrings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline_rounded, size: 60, color: AppColors.textMuted(context)),
          const SizedBox(height: 16),
          Text(s.loginToWatchlist, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/login'), child: Text(s.login)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(AppStrings.of(context).watchlist, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text(context))),
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

  Widget _buildMediaTypeTabs(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildMediaTypeTab(context, s.all, 'all', Icons.list_rounded),
          const SizedBox(width: 8),
          _buildMediaTypeTab(context, s.shows, 'tv', Icons.tv_rounded),
          const SizedBox(width: 8),
          _buildMediaTypeTab(context, s.movies, 'movie', Icons.movie_rounded),
        ],
      ),
    );
  }

  Widget _buildMediaTypeTab(BuildContext context, String label, String value, IconData icon) {
    final isSelected = _mediaType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _mediaType = value);
          context.read<WatchlistCubit>().setMediaType(value);
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

  Widget _buildStatusFilters(BuildContext context) {
    final s = AppStrings.of(context);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(context, s.all, 'all'),
          _buildFilterChip(context, s.statusWatching, 'watching'),
          _buildFilterChip(context, s.statusCompleted, 'completed'),
          _buildFilterChip(context, s.statusUpToDate, 'up_to_date'),
          _buildFilterChip(context, s.statusWatchlist, 'watchlist'),
          _buildFilterChip(context, s.statusStopped, 'stopped'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
    final s = AppStrings.of(context);
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
                ElevatedButton(onPressed: _loadWatchlist, child: Text(s.retry)),
              ],
            ),
          );
        }

        if (state is WatchlistLoaded) {
          final items = _getFilteredItems(state);

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline_rounded, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text(s.watchlistEmpty, style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(s.addShowsToWatchLater, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.search_rounded),
                    label: Text(s.findShows),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildItemCard(context, items[index]),
          );
        }

        return const SizedBox();
      },
    );
  }

  List<WatchlistItem> _getFilteredItems(WatchlistLoaded state) {
    List<WatchlistItem> items = state.items;

    // Filter by media type
    if (_mediaType == 'tv') {
      items = items.where((i) => i.mediaType == 'tv').toList();
    } else if (_mediaType == 'movie') {
      items = items.where((i) => i.mediaType == 'movie').toList();
    }

    // Filter by status
    if (_filter != 'all') {
      items = items.where((i) => i.status == _filter).toList();
    }

    return items;
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
        onTap: () async {
          await context.push(isShow ? '/show/$id' : '/movie/$id');
          if (mounted) _loadWatchlist();
        },
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
              onPressed: () => _showRemoveDialog(context, item, id),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, WatchlistItem item, int id) {
    final s = AppStrings.of(context);
    final isShow = item.mediaType == 'tv';
    final name = isShow ? (item.model as ShowModel).name : (item.model as MovieModel).title;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.removeFromWatchlist),
        content: Text(s.removeFromWatchlistConfirm(name)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface(context),
              foregroundColor: AppColors.text(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.cancel, style: TextStyle(color: AppColors.textMuted(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WatchlistCubit>().removeFromWatchlist(id, item.mediaType);
            },
            child: Text(s.remove, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, int tmdbId, String mediaType) {
    final s = AppStrings.of(context);
    Color color;
    String label;
    switch (status) {
      case 'watching':
        color = AppColors.info;
        label = s.statusWatching;
        break;
      case 'completed':
        color = AppColors.success;
        label = s.statusCompleted;
        break;
      case 'up_to_date':
        color = AppColors.warning;
        label = s.statusUpToDate;
        break;
      case 'stopped':
        color = AppColors.error;
        label = s.statusStopped;
        break;
      default:
        color = AppColors.textMuted(context);
        label = s.statusWatchlist;
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
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.changeStatus, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        children: [
          _buildStatusOption(ctx, s.statusWatchlist, 'watchlist', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, s.statusWatching, 'watching', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, s.statusCompleted, 'completed', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, s.statusUpToDate, 'up_to_date', currentStatus, tmdbId, mediaType),
          _buildStatusOption(ctx, s.statusStopped, 'stopped', currentStatus, tmdbId, mediaType),
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
          if (value == 'completed' && mediaType == 'tv' && current != 'completed') {
            _showMarkAllDialog(context, tmdbId, mediaType, value);
          } else {
            context.read<WatchlistCubit>().updateStatus(tmdbId, mediaType, value);
          }
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

  void _showMarkAllDialog(BuildContext ctx, int tmdbId, String mediaType, String newStatus) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.markAsCompletedQuestion, style: TextStyle(color: AppColors.text(context))),
        content: Text(s.markAllWatchedQuestion, style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<WatchlistCubit>().updateStatus(tmdbId, mediaType, newStatus);
            },
            child: Text(s.noJustChangeStatus, style: TextStyle(color: AppColors.textMuted(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              context.read<WatchlistCubit>().updateStatus(tmdbId, mediaType, newStatus);
              await context.push('/show/$tmdbId');
              if (mounted) _loadWatchlist();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.yesMarkAll),
          ),
        ],
      ),
    );
  }
}
