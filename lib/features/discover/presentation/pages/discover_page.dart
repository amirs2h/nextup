import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/discover_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/modern_widgets.dart';
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
        final genreId = widget.filters!['genreId'] as int?;
        if (genreId != null) {
          context.read<DiscoverCubit>().filterByGenre(genreId, _mediaType);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildMediaTypeToggle(),
              _buildGenreChips(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text('Discover', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/filters'),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: const Icon(Icons.tune, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.read<DiscoverCubit>().clearFilter(),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: const Icon(Icons.refresh, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildMediaTypeChip('TV Shows', 'tv'),
          const SizedBox(width: 8),
          _buildMediaTypeChip('Movies', 'movie'),
        ],
      ),
    );
  }

  Widget _buildMediaTypeChip(String label, String value) {
    final isSelected = _mediaType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _mediaType = value);
        final state = context.read<DiscoverCubit>().state;
        if (state is DiscoverLoaded && state.selectedGenreId != null) {
          context.read<DiscoverCubit>().filterByGenre(state.selectedGenreId!, value);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFFF3D47)]) : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildGenreChips() {
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

  Widget _buildContent() {
    return BlocBuilder<DiscoverCubit, DiscoverState>(
      builder: (context, state) {
        if (state is DiscoverLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }

        if (state is DiscoverError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(color: Colors.white70)),
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
                  Icon(Icons.explore_off, size: 60, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No content found', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ],
              ),
            );
          }

          return GridView.builder(
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
                              ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.white.withOpacity(0.1), child: const Icon(Icons.movie, color: Colors.white24)))
                              : Container(color: Colors.white.withOpacity(0.1), child: const Icon(Icons.movie, color: Colors.white24)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 12), const SizedBox(width: 2), Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11))]),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }
}
