import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';

import '../../../auth/domain/auth_cubit.dart';
import '../../domain/shared_lists_cubit.dart';

class SharedListsPage extends StatefulWidget {
  const SharedListsPage({super.key});

  @override
  State<SharedListsPage> createState() => _SharedListsPageState();
}

class _SharedListsPageState extends State<SharedListsPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLists();
  }

  void _loadLists() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<SharedListsCubit>().loadSharedLists();
    }
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
          onPressed: () => _showCreateDialog(context),
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
          Row(
            children: [
              Icon(Icons.people_alt_rounded, color: AppColors.electricPurple, size: 24),
              const SizedBox(width: 8),
              Text('Shared Lists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
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
                  onPressed: () => context.read<SharedListsCubit>().loadSharedLists(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is SharedListsLoaded) {
          if (state.lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No shared lists yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Create a list with friends', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SharedListsCubit>().loadSharedLists();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.lists.length,
              itemBuilder: (context, index) {
                final listData = state.lists[index];
                final list = listData['shared_lists'] ?? listData;
                final name = list['name'] ?? 'Untitled';
                final description = list['description'] ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        final listId = list['id'];
                        if (listId != null) {
                          context.push('/shared-list/$listId', extra: name);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.electricPurple, AppColors.neonPurple]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.movie_outlined, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.w600)),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(description, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        }

        return const SizedBox();
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: AppColors.electricPurple),
            const SizedBox(width: 8),
            Text('Create Shared List', style: TextStyle(color: AppColors.text(context))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: 'List name',
                hintStyle: TextStyle(color: AppColors.textMuted(context)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                hintStyle: TextStyle(color: AppColors.textMuted(context)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricPurple)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                context.read<SharedListsCubit>().createSharedList(
                  name: nameController.text,
                  description: descController.text.isNotEmpty ? descController.text : null,
                  memberIds: [],
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricPurple),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}














