import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/dialog_helper.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/custom_lists_cubit.dart';

class CustomListsPage extends StatefulWidget {
  const CustomListsPage({super.key});

  @override
  State<CustomListsPage> createState() => _CustomListsPageState();
}

class _CustomListsPageState extends State<CustomListsPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLists();
  }

  void _loadLists() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<CustomListsCubit>().loadCustomLists();
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
              Icon(Icons.playlist_play_rounded, color: AppColors.electricPurple, size: 28),
              const SizedBox(width: 8),
              Text('My Lists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
        ],
      ),
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
                  onPressed: () => context.read<CustomListsCubit>().loadCustomLists(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Back from detail page — state is CustomListDetailLoaded, reload list
        if (state is! CustomListsLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<CustomListsCubit>().loadCustomLists();
          });
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state.lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play_rounded, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No custom lists yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Create your own collection', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CustomListsCubit>().loadCustomLists();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.lists.length,
              itemBuilder: (context, index) {
                final list = state.lists[index];
                final name = list['name'] ?? 'Untitled';
                final description = list['description'] ?? '';
                final isPublic = list['is_public'] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        final listId = list['id'];
                        if (listId != null) {
                          context.push('/custom-list/$listId', extra: name);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPublic 
                                    ? [AppColors.success, AppColors.success]
                                    : [AppColors.electricPurple, AppColors.neonPurple],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPublic ? Icons.public : Icons.lock_outline,
                              color: Colors.white,
                              size: 24,
                            ),
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
                                const SizedBox(height: 4),
                                Text(isPublic ? 'Public' : 'Private', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
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
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: DialogHelper.titleWithIcon(Icons.playlist_play_rounded, AppColors.electricPurple, 'Create List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogHelper.dialogTextField(controller: nameController, hintText: 'List name', context: context),
              const SizedBox(height: 12),
              DialogHelper.dialogTextField(controller: descController, hintText: 'Description (optional)', context: context),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(isPublic ? Icons.public : Icons.lock_outline, color: AppColors.textMuted(context), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(isPublic ? 'Public list' : 'Private list', style: TextStyle(color: AppColors.text(context)))),
                  Switch(
                    value: isPublic,
                    onChanged: (value) => setState(() => isPublic = value),
                    activeColor: AppColors.electricPurple,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              children: DialogHelper.cancelConfirmActions(
                context,
                confirmLabel: 'Create',
                confirmIcon: Icons.add_rounded,
                onConfirm: nameController.text.isNotEmpty ? () {
                  Navigator.pop(dialogContext);
                  context.read<CustomListsCubit>().createCustomList(
                    name: nameController.text,
                    description: descController.text.isNotEmpty ? descController.text : null,
                    isPublic: isPublic,
                  );
                } : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}














