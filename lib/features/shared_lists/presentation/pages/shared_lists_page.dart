import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/dialog_helper.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../domain/shared_lists_cubit.dart';

class SharedListsPage extends StatefulWidget {
  const SharedListsPage({super.key});

  @override
  State<SharedListsPage> createState() => _SharedListsPageState();
}

class _SharedListsPageState extends State<SharedListsPage> {
  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    context.read<SharedListsCubit>().loadSharedLists();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
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
                          Text('Shared Lists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          Text('Watch together with friends', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCreateDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: BlocBuilder<SharedListsCubit, SharedListsState>(
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
                            ElevatedButton(onPressed: _loadLists, child: const Text('Retry')),
                          ],
                        ),
                      );
                    }

                    // Back from detail page — state is SharedListDetailLoaded, reload list
                    if (state is! SharedListsLoaded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _loadLists();
                      });
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    if (state.lists.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 60, color: AppColors.textMuted(context)),
                              const SizedBox(height: 16),
                              Text('No shared lists yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('Create a list to watch together with friends', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => _loadLists(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.lists.length,
                          itemBuilder: (context, index) {
                            final listData = state.lists[index];
                            final list = listData['shared_lists'] ?? listData;
                            final listId = list['id'] as String?;
                            final name = list['name'] ?? 'Untitled';
                            final description = list['description'] ?? '';
                            final createdAt = list['created_at'] != null ? DateTime.tryParse(list['created_at']) : null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => context.push('/shared-list/$listId'),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.electricPurple.withValues(alpha: 0.3),
                                              AppColors.primary.withValues(alpha: 0.2),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.people_rounded, color: AppColors.electricPurple, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15)),
                                            if (description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(description, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                            if (createdAt != null) ...[
                                              const SizedBox(height: 4),
                                              Text(timeago.format(createdAt), style: TextStyle(color: AppColors.textMuted(context), fontSize: 10)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final searchController = TextEditingController();
    List<Map<String, dynamic>> _selectedMembers = [];
    List<Map<String, dynamic>> _following = [];
    List<Map<String, dynamic>> _searchResults = [];
    bool _isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Load following users on first build
          if (_following.isEmpty) {
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthAuthenticated) {
              context.read<SupabaseService>().getFollowing(authState.user.id).then((data) {
                setDialogState(() => _following = data);
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: DialogHelper.titleWithIcon(Icons.people_alt_rounded, AppColors.electricPurple, 'Create Shared List'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    DialogHelper.dialogTextField(controller: nameController, hintText: 'List name', context: context, onChanged: (v) => setDialogState(() {})),
                    const SizedBox(height: 12),
                    // Description field
                    DialogHelper.dialogTextField(controller: descController, hintText: 'Description (optional)', context: context),
                    const SizedBox(height: 20),
                    // Add Members section
                    Text('Add Members', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    // Search field
                    TextField(
                      controller: searchController,
                      style: TextStyle(color: AppColors.text(context), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted(context), size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.electricPurple),
                        ),
                        isDense: true,
                      ),
                      onChanged: (query) async {
                        if (query.trim().length < 2) {
                          setDialogState(() {
                            _searchResults = [];
                            _isSearching = false;
                          });
                          return;
                        }
                        setDialogState(() => _isSearching = true);
                        final results = await context.read<SupabaseService>().searchUsers(query.trim());
                        setDialogState(() {
                          _searchResults = results.take(5).toList();
                          _isSearching = false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Search results
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      ),
                    if (_searchResults.isNotEmpty)
                      ..._searchResults.map((user) {
                        final uid = user['id'] as String?;
                        final username = user['username'] ?? 'User';
                        final avatarUrl = user['avatar_url'] as String?;
                        final isSelected = _selectedMembers.any((m) => m['id'] == uid);
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border(context))),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Container(color: AppColors.cardBg(context), child: Text(username[0].toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.text(context)))))
                                  : Container(color: AppColors.cardBg(context), child: Text(username[0].toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.text(context)))),
                            ),
                          ),
                          title: Text(username, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.add_circle_outline,
                            color: isSelected ? AppColors.success : AppColors.textMuted(context),
                            size: 20,
                          ),
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                _selectedMembers.removeWhere((m) => m['id'] == uid);
                              } else {
                                _selectedMembers.add({'id': uid, 'username': username, 'avatar_url': avatarUrl});
                              }
                            });
                          },
                        );
                      }),
                    // Following list (first 10)
                    if (_following.isNotEmpty && searchController.text.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Following', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                      const SizedBox(height: 4),
                      ..._following.take(10).map((user) {
                        final uid = user['following_id'] as String?;
                        final username = user['profiles']?['username'] ?? 'User';
                        final avatarUrl = user['profiles']?['avatar_url'] as String?;
                        final isSelected = _selectedMembers.any((m) => m['id'] == uid);
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border(context))),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Container(color: AppColors.cardBg(context), child: Text(username[0].toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.text(context)))))
                                  : Container(color: AppColors.cardBg(context), child: Text(username[0].toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.text(context)))),
                            ),
                          ),
                          title: Text(username, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.add_circle_outline,
                            color: isSelected ? AppColors.success : AppColors.textMuted(context),
                            size: 20,
                          ),
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                _selectedMembers.removeWhere((m) => m['id'] == uid);
                              } else {
                                _selectedMembers.add({'id': uid, 'username': username, 'avatar_url': avatarUrl});
                              }
                            });
                          },
                        );
                      }),
                    ],
                    // Selected members chips
                    if (_selectedMembers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Selected (${_selectedMembers.length})', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedMembers.map((member) {
                          return Chip(
                            label: Text(member['username'], style: TextStyle(color: AppColors.text(context), fontSize: 11)),
                            deleteIcon: Icon(Icons.close, size: 14, color: AppColors.textMuted(context)),
                            onDeleted: () => setDialogState(() => _selectedMembers.remove(member)),
                            backgroundColor: AppColors.cardBg(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: AppColors.border(context)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: DialogHelper.cancelConfirmActions(
                  context,
                  confirmLabel: 'Create',
                  confirmIcon: Icons.add_rounded,
                  onConfirm: nameController.text.isNotEmpty ? () {
                    Navigator.pop(dialogContext);
                    context.read<SharedListsCubit>().createSharedList(
                      name: nameController.text,
                      description: descController.text.isNotEmpty ? descController.text : null,
                      memberIds: _selectedMembers.map((m) => m['id'] as String).toList(),
                    );
                  } : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
