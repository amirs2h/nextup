import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../domain/shared_lists_cubit.dart';
import '../../../../shared/services/supabase_service.dart';

class SharedListDetailPage extends StatefulWidget {
  final String listId;
  final String listName;
  const SharedListDetailPage({super.key, required this.listId, required this.listName});

  @override
  State<SharedListDetailPage> createState() => _SharedListDetailPageState();
}

class _SharedListDetailPageState extends State<SharedListDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SharedListsCubit>().loadSharedListDetail(widget.listId);
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
                Text(widget.listName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                Text('Shared List', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showMembersSheet(context),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.people_outline, color: AppColors.text(context), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<SharedListsCubit, SharedListsState>(
      builder: (context, state) {
        if (state is SharedListsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is SharedListsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<SharedListsCubit>().loadSharedListDetail(widget.listId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is SharedListDetailLoaded) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_outlined, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No items yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap + to add shows or movies', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              final tmdbId = item['tmdb_id'];
              final mediaType = item['media_type'] ?? 'tv';
              final title = item['title'] ?? 'Unknown';
              final posterPath = item['poster_path'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => context.push(mediaType == 'tv' ? '/show/$tmdbId' : '/movie/$tmdbId'),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 85,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: posterPath != null
                                ? CachedNetworkImage(
                                    imageUrl: AppConfig.getImageUrl(posterPath, size: 'w92'),
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.cardBg(context),
                                      child: Icon(mediaType == 'tv' ? Icons.tv : Icons.movie_outlined, color: AppColors.textMuted(context)),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.cardBg(context),
                                    child: Icon(mediaType == 'tv' ? Icons.tv : Icons.movie_outlined, color: AppColors.textMuted(context)),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(mediaType == 'tv' ? 'TV Show' : 'Movie', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
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
                                title: const Text('Remove Item'),
                                content: const Text('Remove this item from the list?'),
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
                                      context.read<SharedListsCubit>().removeItemFromList(widget.listId, tmdbId, mediaType);
                                    },
                                    child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  void _showMembersSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BlocBuilder<SharedListsCubit, SharedListsState>(
        builder: (context, state) {
          List<Map<String, dynamic>> members = [];
          if (state is SharedListDetailLoaded) {
            members = state.members;
          }
          return SimpleDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Expanded(
                  child: Text('Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddMemberDialog(context);
                  },
                  icon: const Icon(Icons.person_add, color: AppColors.electricPurple),
                ),
              ],
            ),
            children: [
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No members yet', style: TextStyle(color: AppColors.textMuted(context))),
                )
              else
                ...members.map((member) {
                  final username = member['profiles']?['username'] ?? 'User';
                  final role = member['role'] ?? 'member';
                  final userId = member['user_id'];
                  return SimpleDialogOption(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: role == 'admin' ? AppColors.electricPurple : AppColors.cardBg(context),
                          child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: TextStyle(color: AppColors.text(context), fontSize: 16)),
                              Text(role, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                            ],
                          ),
                        ),
                        if (role != 'admin')
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: AppColors.surface(context),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Remove Member'),
                                  content: const Text('Remove this member from the list?'),
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
                                        context.read<SharedListsCubit>().removeMember(widget.listId, userId);
                                      },
                                      child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person_add, color: AppColors.electricPurple),
              const SizedBox(width: 8),
              Text('Add Member', style: TextStyle(color: AppColors.text(context))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: InputDecoration(
                    hintText: 'Search by username',
                    hintStyle: TextStyle(color: AppColors.textMuted(context)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
                    suffixIcon: IconButton(
                      onPressed: () async {
                        if (searchController.text.isNotEmpty) {
                          setDialogState(() => isSearching = true);
                          try {
                            final supabase = context.read<SupabaseService>();
                            final results = await supabase.searchUsers(searchController.text);
                            setDialogState(() {
                              searchResults = results;
                              isSearching = false;
                            });
                          } catch (e) {
                            setDialogState(() => isSearching = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Search failed. Please try again.'), backgroundColor: AppColors.error),
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
                        final supabase = context.read<SupabaseService>();
                        final results = await supabase.searchUsers(searchController.text);
                        setDialogState(() {
                          searchResults = results;
                          isSearching = false;
                        });
                      } catch (e) {
                        setDialogState(() => isSearching = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Search failed. Please try again.'), backgroundColor: AppColors.error),
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
                  Text('No users found', style: TextStyle(color: AppColors.textMuted(context)))
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        final username = user['username'] ?? 'User';
                        final userId = user['id'];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.cardBg(context),
                            child: Text(username[0].toUpperCase(), style: TextStyle(color: AppColors.text(context))),
                          ),
                          title: Text(username, style: TextStyle(color: AppColors.text(context))),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            context.read<SharedListsCubit>().addMember(widget.listId, userId);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
            ),
          ],
        ),
      ),
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
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: AppColors.electricPurple),
              const SizedBox(width: 8),
              Text('Add Item', style: TextStyle(color: AppColors.text(context))),
            ],
          ),
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
                            setDialogState(() => isSearching = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Search failed. Please try again.'), backgroundColor: AppColors.error),
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
                        setDialogState(() => isSearching = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Search failed. Please try again.'), backgroundColor: AppColors.error),
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
                            context.read<SharedListsCubit>().addItemToList(widget.listId, tmdbId, mediaType);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
            ),
          ],
        ),
      ),
    );
  }
}
