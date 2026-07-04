import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/watchlist_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../shared/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
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
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthUnauthenticated) {
                return _buildLoginPrompt();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildFilterTabs(),
                  Expanded(child: _buildContent()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Please login to view your watchlist', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Login')),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Text('Watchlist', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          GestureDetector(
            onTap: _loadWatchlist,
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

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Shows', 'shows'),
          const SizedBox(width: 8),
          _buildFilterChip('Movies', 'movies'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        context.read<WatchlistCubit>().setFilter(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildContent() {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, state) {
        if (state is WatchlistLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }

        if (state is WatchlistError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadWatchlist, child: const Text('Retry')),
              ],
            ),
          );
        }

        if (state is WatchlistLoaded) {
          final shows = _filter == 'movies' ? [] : state.shows;
          final movies = _filter == 'shows' ? [] : state.movies;

          if (shows.isEmpty && movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline, size: 60, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Your watchlist is empty', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Add shows and movies to watch later', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('Find Shows'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (shows.isNotEmpty) ...[
                const Text('Shows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ...shows.map((show) => _buildShowCard(show)),
                const SizedBox(height: 20),
              ],
              if (movies.isNotEmpty) ...[
                const Text('Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ...movies.map((movie) => _buildMovieCard(movie)),
              ],
              const SizedBox(height: 100),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildShowCard(ShowModel show) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/show/${show.id}'),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 85,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: show.posterUrl != null
                    ? CachedNetworkImage(imageUrl: show.posterUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Colors.white24))
                    : Container(color: Colors.white.withOpacity(0.1), child: const Icon(Icons.movie, color: Colors.white24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 16), const SizedBox(width: 4), Text(show.voteAverage.toStringAsFixed(1), style: TextStyle(color: Colors.white.withOpacity(0.7)))]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF4757)),
              onPressed: () => context.read<WatchlistCubit>().removeFromWatchlist(show.id, 'tv'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(MovieModel movie) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/movie/${movie.id}'),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 85,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: movie.posterUrl != null
                    ? CachedNetworkImage(imageUrl: movie.posterUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Colors.white24))
                    : Container(color: Colors.white.withOpacity(0.1), child: const Icon(Icons.movie, color: Colors.white24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 16), const SizedBox(width: 4), Text(movie.voteAverage.toStringAsFixed(1), style: TextStyle(color: Colors.white.withOpacity(0.7)))]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF4757)),
              onPressed: () => context.read<WatchlistCubit>().removeFromWatchlist(movie.id, 'movie'),
            ),
          ],
        ),
      ),
    );
  }
}
