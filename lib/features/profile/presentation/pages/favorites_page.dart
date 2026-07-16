import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/domain/auth_cubit.dart';

import '../../domain/favorites_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../shared/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      await context.read<FavoritesCubit>().loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
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
            onTap: () => context.pop(),
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
          Text('Favorites', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is FavoritesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<FavoritesCubit>().loadFavorites(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is FavoritesLoaded) {
          if (state.shows.isEmpty && state.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                Text('No favorites yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
                  const SizedBox(height: 8),
                  Text('Add shows and movies to your favorites', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFavorites,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (state.shows.isNotEmpty) ...[
                  Text('Shows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 12),
                  ...state.shows.map((show) => _buildShowCard(context, show)),
                  const SizedBox(height: 20),
                ],
                if (state.movies.isNotEmpty) ...[
                  Text('Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 12),
                  ...state.movies.map((movie) => _buildMovieCard(context, movie)),
                ],
                const SizedBox(height: 100),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildShowCard(BuildContext context, ShowModel show) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () async {
          await context.push('/show/${show.id}');
          if (mounted) _loadFavorites();
        },
        child: Row(
          children: [
            Container(
              width: 60,
              height: 85,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: show.posterUrl != null
                    ? CachedNetworkImage(imageUrl: show.posterUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Icon(Icons.movie, color: AppColors.textMuted(context)))
                    : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 16), const SizedBox(width: 4), Text(show.voteAverage.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13))]),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _confirmRemove(context, show.name, () => context.read<FavoritesCubit>().removeFromFavorites(show.id, 'tv')),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(BuildContext context, MovieModel movie) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () async {
          await context.push('/movie/${movie.id}');
          if (mounted) _loadFavorites();
        },
        child: Row(
          children: [
            Container(
              width: 60,
              height: 85,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: movie.posterUrl != null
                    ? CachedNetworkImage(imageUrl: movie.posterUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Icon(Icons.movie, color: AppColors.textMuted(context)))
                    : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 16), const SizedBox(width: 4), Text(movie.voteAverage.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13))]),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _confirmRemove(context, movie.title, () => context.read<FavoritesCubit>().removeFromFavorites(movie.id, 'movie')),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, String name, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove from Favorites'),
        content: Text('Remove "$name" from your favorites?'),
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
              onConfirm();
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}














