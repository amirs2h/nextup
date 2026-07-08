import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/discover_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../shared/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';

class DiscoverPage extends StatefulWidget {
  final Map<String, dynamic>? filters;
  const DiscoverPage({super.key, this.filters});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _mediaType = 'tv';

  @override
  void initState() {
    super.initState();
    if (widget.filters != null) {
      _mediaType = widget.filters!['mediaType'] ?? 'tv';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final genreId = widget.filters!['genreId'] as int?;
        final sortBy = widget.filters!['sortBy'] as String?;
        final year = widget.filters!['year'] as int?;
        final minRating = widget.filters!['minRating'] as double?;
        final showStatus = widget.filters!['showStatus'] as int?;

        context.read<DiscoverCubit>().applyFilters(
          mediaType: _mediaType,
          sortBy: sortBy,
          year: year,
          minRating: minRating,
          genreId: genreId,
          showStatus: showStatus,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: BlocListener<DiscoverCubit, DiscoverState>(
        listener: (context, state) {
          if (state is DiscoverLoaded) {
            if (_mediaType != state.mediaType) {
              setState(() => _mediaType = state.mediaType);
            }
          }
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildMediaTypeToggle(context),
              _buildGenreChips(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text('Discover', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/filters'),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.tune_rounded, color: AppColors.text(context), size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.read<DiscoverCubit>().clearFilter(),
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

  Widget _buildMediaTypeToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildMediaTypeChip(context, 'TV Shows', 'tv'),
          const SizedBox(width: 8),
          _buildMediaTypeChip(context, 'Movies', 'movie'),
        ],
      ),
    );
  }

  Widget _buildMediaTypeChip(BuildContext context, String label, String value) {
    final isSelected = _mediaType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _mediaType = value);
        final state = context.read<DiscoverCubit>().state;
        if (state is DiscoverLoaded) {
          // Always apply filters with current state when toggling media type
          context.read<DiscoverCubit>().applyFilters(
            mediaType: value,
            sortBy: state.sortBy,
            year: state.year,
            minRating: state.minRating > 0 ? state.minRating : null,
            genreId: state.selectedGenreId,
            showStatus: value == 'tv' ? state.showStatus : null,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
      ),
    );
  }

  Widget _buildGenreChips(BuildContext context) {
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        if (state is! DiscoverLoaded) return const SizedBox();

        return SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.genres.length,
            itemBuilder: (context, index) {
              final genre = state.genres[index];
              final isSelected = state.selectedGenreId == genre.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ModernGenreChip(
                  label: genre.name,
                  isSelected: isSelected,
                  onTap: () {
                    if (isSelected) {
                      context.read<DiscoverCubit>().clearFilter();
                    } else {
                      context.read<DiscoverCubit>().filterByGenre(genre.id, _mediaType);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        if (state is DiscoverLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is DiscoverError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<DiscoverCubit>().clearFilter(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is DiscoverLoaded) {
          final items = _mediaType == 'tv' ? state.shows : state.movies;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore_off, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No content found', style: TextStyle(color: AppColors.textMuted(context))),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DiscoverCubit>().loadGenres();
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final String title;
                final String? posterUrl;
                final int id;
                final double rating;

                if (_mediaType == 'tv') {
                  final show = item as ShowModel;
                  title = show.name;
                  posterUrl = show.posterUrl;
                  id = show.id;
                  rating = show.voteAverage;
                } else {
                  final movie = item as MovieModel;
                  title = movie.title;
                  posterUrl = movie.posterUrl;
                  id = movie.id;
                  rating = movie.voteAverage;
                }

                return GestureDetector(
                  onTap: () => context.push(_mediaType == 'tv' ? '/show/$id' : '/movie/$id'),
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
                                ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie_rounded, color: AppColors.textMuted(context))))
                                : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie_rounded, color: AppColors.textMuted(context))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 12), const SizedBox(width: 2), Text(rating.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11))]),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}
