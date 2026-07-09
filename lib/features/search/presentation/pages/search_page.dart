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
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.length >= 2) {
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
            Padding(
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
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                context.read<SearchCubit>().clear();
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
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchInitial) {
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

                    final items = <Map<String, dynamic>>[];
                    
                    // Add users
                    for (final user in state.users) {
                      items.add({'type': 'user', 'data': user});
                    }
                    // Add shows
                    for (final show in state.shows) {
                      items.add({'type': 'show', 'data': show});
                    }
                    // Add movies
                    for (final movie in state.movies) {
                      items.add({'type': 'movie', 'data': movie});
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item['type'] == 'user') {
                          return _buildUserResultItem(context, user: item['data'] as Map<String, dynamic>);
                        } else if (item['type'] == 'show') {
                          final show = item['data'];
                          return _buildSearchResultItem(context, id: show.id, title: show.name, subtitle: _getYear(show.firstAirDate), rating: show.voteAverage, posterPath: show.posterPath, isMovie: false);
                        } else {
                          final movie = item['data'];
                          return _buildSearchResultItem(context, id: movie.id, title: movie.title, subtitle: _getYear(movie.releaseDate), rating: movie.voteAverage, posterPath: movie.posterPath, isMovie: true);
                        }
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
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
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.cardBg(context)),
              child: posterPath != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: AppConfig.getImageUrl(posterPath, size: 'w92'), fit: BoxFit.cover, errorWidget: (context, url, error) => Center(child: Icon(Icons.movie, color: AppColors.textMuted(context)))))
                  : Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
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
                  Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 16), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13))]),
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














