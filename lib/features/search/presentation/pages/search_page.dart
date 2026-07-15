import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/search_cubit.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length >= 1) {
        context.read<SearchCubit>().search(query);
      } else if (query.isEmpty) {
        context.read<SearchCubit>().clear();
      }
    });
  }

  String _getYear(String? date) {
    if (date == null || date.length < 4) return '';
    return date.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textMuted(context), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'Search shows, movies, people...',
                        hintStyle: TextStyle(color: AppColors.textMuted(context)),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _onSearchChanged(value);
                        setState(() {});
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        context.read<SearchCubit>().clear();
                        setState(() {});
                      },
                      child: Icon(Icons.close, color: AppColors.textMuted(context), size: 20),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/'),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is SearchInitial) {
          return _buildRecentSearches(context, state.recentSearches);
        }

        if (state is SearchLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is SearchError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      context.read<SearchCubit>().search(_searchController.text);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is SearchLoaded) {
          if (state.users.isEmpty && state.shows.isEmpty && state.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No results found for "${state.query}"', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Users section
              if (state.users.isNotEmpty) ...[
                _buildSectionHeader('Users', Icons.people, const Color(0xFF6C63FF)),
                ...state.users.map((user) => _buildUserResultItem(context, user: user)),
                const SizedBox(height: 16),
              ],
              // Shows section
              if (state.shows.isNotEmpty) ...[
                _buildSectionHeader('TV Shows', Icons.tv, AppColors.primary),
                ...state.shows.map((show) => _buildSearchResultItem(
                  context,
                  id: show.id,
                  title: show.name,
                  subtitle: _getYear(show.firstAirDate),
                  rating: show.voteAverage,
                  posterPath: show.posterPath,
                  isMovie: false,
                )),
                const SizedBox(height: 16),
              ],
              // Movies section
              if (state.movies.isNotEmpty) ...[
                _buildSectionHeader('Movies', Icons.movie, AppColors.electricPurple),
                ...state.movies.map((movie) => _buildSearchResultItem(
                  context,
                  id: movie.id,
                  title: movie.title,
                  subtitle: _getYear(movie.releaseDate),
                  rating: movie.voteAverage,
                  posterPath: movie.posterPath,
                  isMovie: true,
                )),
              ],
              const SizedBox(height: 20),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildRecentSearches(BuildContext context, List<String> recentSearches) {
    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: AppColors.textMuted(context)),
            const SizedBox(height: 16),
            Text('Search for shows, movies, and people', style: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text('Recent Searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text(context))),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<SearchCubit>().clearRecentSearches(),
                child: Text('Clear', style: TextStyle(color: AppColors.electricPurple, fontSize: 14)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              final query = recentSearches[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    context.read<SearchCubit>().search(query);
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: AppColors.textMuted(context), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(query, style: TextStyle(color: AppColors.text(context), fontSize: 15)),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            context.read<SearchCubit>().clear();
                          },
                          child: Icon(Icons.north_west, color: AppColors.textMuted(context), size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildUserResultItem(BuildContext context, {required Map<String, dynamic> user}) {
    final username = user['username'] ?? 'User';
    final bio = user['bio'] ?? '';
    final avatarUrl = user['avatar_url'];
    final userId = user['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/user/$userId'),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.electricPurple, AppColors.neonPurple]),
              ),
              child: avatarUrl != null
                  ? ClipOval(child: CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)))))
                  : Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15)),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(bio, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, {required int id, required String title, required String subtitle, required double rating, String? posterPath, required bool isMovie}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push(isMovie ? '/movie/$id' : '/show/$id'),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 85,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posterPath != null
                    ? CachedNetworkImage(imageUrl: AppConfig.getImageUrl(posterPath, size: 'w92'), fit: BoxFit.cover, errorWidget: (_, __, ___) => Icon(Icons.movie_rounded, color: AppColors.textMuted(context)))
                    : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie_rounded, color: AppColors.textMuted(context))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
          ],
        ),
      ),
    );
  }
}
