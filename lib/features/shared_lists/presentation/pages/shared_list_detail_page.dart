import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/dialog_helper.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../auth/domain/auth_cubit.dart';
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showMenuSheet(context),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.more_vert, color: AppColors.text(context), size: 22),
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
              final watchedBy = item['watched_by'] as List<dynamic>? ?? [];
              final watchProgress = (item['watch_progress'] as num?)?.toDouble() ?? 0.0;
              final allWatched = watchProgress >= 1.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(16),
                  borderColor: allWatched ? AppColors.success.withValues(alpha: 0.3) : null,
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
                              Text(mediaType == 'tv' ? 'TV Show' : 'Movie', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                              const SizedBox(height: 6),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: watchProgress,
                                  minHeight: 5,
                                  backgroundColor: AppColors.cardBg(context),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    allWatched ? AppColors.success : AppColors.electricPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Stacked avatars + text
                              Row(
                                children: [
                                  if (watchedBy.isNotEmpty)
                                    SizedBox(
                                      width: (watchedBy.length.clamp(0, 3) * 16.0) + 16,
                                      height: 22,
                                      child: Stack(
                                        children: [
                                          for (int i = 0; i < watchedBy.length.clamp(0, 3); i++)
                                            Positioned(
                                              left: i * 16.0,
                                              child: Container(
                                                width: 22,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: AppColors.background(context), width: 1.5),
                                                ),
                                                child: ClipOval(
                                                  child: (watchedBy[i]['avatar_url'] as String?)?.isNotEmpty == true
                                                      ? CachedNetworkImage(
                                                          imageUrl: watchedBy[i]['avatar_url'],
                                                          fit: BoxFit.cover,
                                                          errorWidget: (c, u, e) => Container(
                                                            color: AppColors.cardBg(context),
                                                            child: Text((watchedBy[i]['username'] ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: 8, color: AppColors.text(context))),
                                                          ),
                                                        )
                                                      : Container(
                                                          color: AppColors.cardBg(context),
                                                          child: Text((watchedBy[i]['username'] ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: 8, color: AppColors.text(context))),
                                                        ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    allWatched ? 'All watched' : '${watchedBy.length}/${state.members.length} watched',
                                    style: TextStyle(
                                      color: allWatched ? AppColors.success : AppColors.textMuted(context),
                                      fontSize: 11,
                                      fontWeight: allWatched ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
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
                                title: DialogHelper.titleWithIcon(Icons.remove_circle_outline, AppColors.error, 'Remove Item'),
                                content: Text('Remove "$title" from this list?', style: TextStyle(color: AppColors.textSecondary(context))),
                                actions: [
                                  Row(
                                    children: DialogHelper.cancelDangerActions(
                                      context,
                                      dangerLabel: 'Remove',
                                      dangerIcon: Icons.delete_outline,
                                      onDanger: () {
                                        Navigator.pop(dialogContext);
                                        context.read<SharedListsCubit>().removeItemFromList(widget.listId, tmdbId, mediaType);
                                      },
                                    ),
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
                                  title: DialogHelper.titleWithIcon(Icons.person_remove, AppColors.error, 'Remove Member'),
                                  content: Text('Remove $username from the list?', style: TextStyle(color: AppColors.text(context))),
                                  actions: DialogHelper.cancelDangerActions(
                                    dialogContext,
                                    dangerLabel: 'Remove',
                                    dangerIcon: Icons.delete_outline,
                                    onDanger: () {
                                      Navigator.pop(dialogContext);
                                      context.read<SharedListsCubit>().removeMember(widget.listId, userId);
                                    },
                                  ),
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
          title: DialogHelper.titleWithIcon(Icons.person_add, AppColors.electricPurple, 'Add Member'),
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
          actions: [DialogHelper.cancelButton(dialogContext)],
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
          actions: [DialogHelper.cancelButton(dialogContext)],
        ),
      ),
    );
  }

  void _showMenuSheet(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : null;
    final isCreator = userId != null; // We'll check against creator_id from state

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final cubitState = context.read<SharedListsCubit>().state;
        bool isOwner = false;
        if (cubitState is SharedListDetailLoaded) {
          isOwner = cubitState.list['creator_id'] == userId;
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted(ctx).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Delete List', style: TextStyle(color: AppColors.error)),
                  subtitle: Text('This will permanently delete the list and all items', style: TextStyle(color: AppColors.textMuted(ctx), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteList(context);
                  },
                )
              else
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: AppColors.textMuted(context)),
                  title: Text('Leave List', style: TextStyle(color: AppColors.text(context))),
                  subtitle: Text('You will no longer have access to this list', style: TextStyle(color: AppColors.textMuted(ctx), fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmLeaveList(context);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteList(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: DialogHelper.titleWithIcon(Icons.delete_forever, AppColors.error, 'Delete List'),
        content: Text('Are you sure? This will permanently delete the list and all its items.', style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          Row(
            children: DialogHelper.cancelDangerActions(
              context,
              dangerLabel: 'Delete',
              dangerIcon: Icons.delete_forever,
              onDanger: () {
                Navigator.pop(ctx);
                context.read<SharedListsCubit>().deleteList(widget.listId);
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveList(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: DialogHelper.titleWithIcon(Icons.exit_to_app, AppColors.warning, 'Leave List'),
        content: Text('You will no longer have access to this list.', style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          Row(
            children: DialogHelper.cancelDangerActions(
              context,
              dangerLabel: 'Leave',
              dangerIcon: Icons.exit_to_app,
              onDanger: () {
                Navigator.pop(ctx);
                context.read<SharedListsCubit>().leaveList(widget.listId);
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
