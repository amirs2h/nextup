import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/dialog_helper.dart';
import '../../domain/custom_lists_cubit.dart';
import '../../../../shared/services/tmdb_service.dart';

class CustomListDetailPage extends StatefulWidget {
  final String listId;
  final String listName;
  const CustomListDetailPage({super.key, required this.listId, required this.listName});

  @override
  State<CustomListDetailPage> createState() => _CustomListDetailPageState();
}

class _CustomListDetailPageState extends State<CustomListDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomListsCubit>().loadCustomListDetail(widget.listId);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddItemDialog(context),
          backgroundColor: AppColors.electricPurple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<CustomListsCubit, CustomListsState>(
      builder: (context, state) {
        String description = '';
        bool isPublic = false;
        if (state is CustomListDetailLoaded) {
          description = state.list['description'] ?? '';
          isPublic = state.list['is_public'] ?? false;
        }
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.listName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isPublic ? AppColors.success : AppColors.electricPurple).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isPublic ? Icons.public : Icons.lock_outline, size: 12, color: isPublic ? AppColors.success : AppColors.electricPurple),
                              const SizedBox(width: 4),
                              Text(isPublic ? 'Public' : 'Private', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPublic ? AppColors.success : AppColors.electricPurple)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty)
                      Text(description, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)
                    else
                      Text('Custom List', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showMenuSheet(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardBg(context),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Icon(Icons.more_horiz_rounded, color: AppColors.text(context), size: 22),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<CustomListsCubit, CustomListsState>(
      builder: (context, state) {
        if (state is CustomListsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is CustomListsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<CustomListsCubit>().loadCustomListDetail(widget.listId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Back from show/movie page — state might be CustomListsLoaded, reload
        if (state is! CustomListDetailLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<CustomListsCubit>().loadCustomListDetail(widget.listId);
          });
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
          final shows = state.shows;
          final movies = state.movies;
          final totalItems = shows.length + movies.length;

          if (totalItems == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play_rounded, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No items yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap + to add shows or movies', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (shows.isNotEmpty) ...[
                Text('TV Shows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 12),
                ...shows.map((show) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => context.push('/show/${show.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 85,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: show.posterUrl != null
                                  ? CachedNetworkImage(imageUrl: show.posterUrl!, fit: BoxFit.cover, errorWidget: (c, u, e) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))))
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
                                Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 16), const SizedBox(width: 4), Text(show.voteAverage.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context)))]),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: AppColors.surface(context),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: DialogHelper.titleWithIcon(Icons.delete_outline, AppColors.error, 'Remove Item'),
                                  content: Text('Remove "${show.name}" from this list?', style: TextStyle(color: AppColors.text(context))),
                                  actions: DialogHelper.cancelDangerActions(
                                    dialogContext,
                                    dangerLabel: 'Remove',
                                    dangerIcon: Icons.delete_outline,
                                    onDanger: () {
                                      Navigator.pop(dialogContext);
                                      context.read<CustomListsCubit>().removeItemFromList(widget.listId, show.id, 'tv');
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
              if (movies.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 12),
                ...movies.map((movie) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => context.push('/movie/${movie.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 85,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: movie.posterUrl != null
                                  ? CachedNetworkImage(imageUrl: movie.posterUrl!, fit: BoxFit.cover, errorWidget: (c, u, e) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))))
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
                                Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 16), const SizedBox(width: 4), Text(movie.voteAverage.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context)))]),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: AppColors.surface(context),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: DialogHelper.titleWithIcon(Icons.delete_outline, AppColors.error, 'Remove Item'),
                                  content: Text('Remove "${movie.title}" from this list?', style: TextStyle(color: AppColors.text(context))),
                                  actions: DialogHelper.cancelDangerActions(
                                    dialogContext,
                                    dangerLabel: 'Remove',
                                    dangerIcon: Icons.delete_outline,
                                    onDanger: () {
                                      Navigator.pop(dialogContext);
                                      context.read<CustomListsCubit>().removeItemFromList(widget.listId, movie.id, 'movie');
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
              const SizedBox(height: 100),
            ],
          );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: DialogHelper.titleWithIcon(Icons.add_circle_outline, AppColors.electricPurple, 'Add Item'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: InputDecoration(
                    hintText: 'Search shows or movies',
                    hintStyle: TextStyle(color: AppColors.textMuted(context)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                    suffixIcon: IconButton(
                      onPressed: () async {
                        if (searchController.text.isNotEmpty) {
                          setDialogState(() => isSearching = true);
                          try {
                            final tmdb = context.read<TmdbService>();
                            final results = await tmdb.searchMulti(searchController.text);
                            setDialogState(() {
                              searchResults = List<Map<String, dynamic>>.from(results['results'] ?? []).take(10).toList();
                              isSearching = false;
                            });
                          } catch (e) {
                            setDialogState(() {
                              searchResults = [];
                              isSearching = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text('Search failed. Please try again.'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.search, color: AppColors.electricPurple),
                    ),
                  ),
                  onSubmitted: (_) async {
                    if (searchController.text.isNotEmpty) {
                      setDialogState(() => isSearching = true);
                      try {
                        final tmdb = context.read<TmdbService>();
                        final results = await tmdb.searchMulti(searchController.text);
                        setDialogState(() {
                          searchResults = List<Map<String, dynamic>>.from(results['results'] ?? []).take(10).toList();
                          isSearching = false;
                        });
                      } catch (e) {
                        setDialogState(() {
                          searchResults = [];
                          isSearching = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Search failed. Please try again.'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const CircularProgressIndicator(color: AppColors.electricPurple)
                else if (searchResults.isEmpty)
                  Text('Search for shows or movies', style: TextStyle(color: AppColors.textMuted(context)))
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        final title = item['title'] ?? item['name'] ?? 'Unknown';
                        final mediaType = item['media_type'] ?? 'tv';
                        final tmdbId = item['id'];
                        final posterPath = item['poster_path'];

                        if (mediaType == 'person') return const SizedBox();

                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 66,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: posterPath != null
                                  ? CachedNetworkImage(
                                      imageUrl: AppConfig.getImageUrl(posterPath, size: 'w92'),
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.cardBg(context),
                                        child: Icon(mediaType == 'tv' ? Icons.tv : Icons.movie_outlined, color: AppColors.textMuted(context), size: 20),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.cardBg(context),
                                      child: Icon(mediaType == 'tv' ? Icons.tv : Icons.movie_outlined, color: AppColors.textMuted(context), size: 20),
                                    ),
                            ),
                          ),
                          title: Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 14)),
                          subtitle: Text(mediaType == 'tv' ? 'TV Show' : 'Movie', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            context.read<CustomListsCubit>().addItemToList(widget.listId, tmdbId, mediaType);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
           actions: [DialogHelper.cancelButton(dialogContext)],
        ),
      ),
    );
  }

  void _showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted(ctx).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete List', style: TextStyle(color: AppColors.error)),
                subtitle: Text('This will permanently delete the list and all items', style: TextStyle(color: AppColors.textMuted(ctx), fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteList(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteList(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: DialogHelper.titleWithIcon(Icons.delete_forever, AppColors.error, 'Delete List'),
        content: Text('Are you sure you want to delete "${widget.listName}"? This cannot be undone.', style: TextStyle(color: AppColors.text(context))),
        actions: DialogHelper.cancelDangerActions(
          dialogContext,
          dangerLabel: 'Delete',
          dangerIcon: Icons.delete_forever,
          onDanger: () {
            Navigator.pop(dialogContext);
            context.read<CustomListsCubit>().deleteList(widget.listId);
            context.pop();
          },
        ),
      ),
    );
  }
}
