import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import '../../features/auth/domain/auth_cubit.dart';
import '../widgets/glass_container.dart';
import '../../core/theme/app_colors.dart';

class FavoriteActorVotingWidget extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  final List<dynamic> cast;

  const FavoriteActorVotingWidget({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    required this.cast,
  });

  @override
  State<FavoriteActorVotingWidget> createState() => _FavoriteActorVotingWidgetState();
}

class _FavoriteActorVotingWidgetState extends State<FavoriteActorVotingWidget> {
  int _refreshKey = 0;

  void _refreshVotes() {
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final supabase = context.read<SupabaseService>();
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Who's Your Favorite?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 4),
        Text('Vote for your favorite actor', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
        const SizedBox(height: 12),
        if (userId == null)
          _buildVotingUI(context, supabase, null)
        else
          FutureBuilder<Map<String, dynamic>?>(
            key: ValueKey(_refreshKey),
            future: supabase.getUserFavoriteActorVote(userId: userId, tmdbId: widget.tmdbId, mediaType: widget.mediaType),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError) {
                return const SizedBox();
              }
              final userVote = snapshot.data;
              if (userVote != null) {
                return _buildVotingResults(context, supabase, userVote);
              }
              return _buildVotingUI(context, supabase, userId);
            },
          ),
      ],
    );
  }

  Widget _buildVotingUI(BuildContext context, SupabaseService supabase, String? userId) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.cast.length.clamp(0, 10),
        itemBuilder: (context, index) {
          final person = widget.cast[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                if (userId == null) return;
                try {
                  await supabase.voteFavoriteActor(
                    userId: userId,
                    tmdbId: widget.tmdbId,
                    mediaType: widget.mediaType,
                    personId: person.id,
                    characterName: person.character,
                  );
                  if (context.mounted) _refreshVotes();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Failed to vote. Please try again.'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border(context), width: 2),
                      image: person.profileUrl != null
                          ? DecorationImage(image: CachedNetworkImageProvider(person.profileUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: person.profileUrl == null
                        ? Icon(Icons.person, color: AppColors.textMuted(context), size: 30)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      person.name,
                      style: TextStyle(color: AppColors.text(context), fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Vote', style: TextStyle(color: AppColors.electricPurple, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVotingResults(BuildContext context, SupabaseService supabase, Map<String, dynamic> userVote) {
    final votedPersonId = userVote['person_id'] as int? ?? 0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.getFavoriteActorResults(tmdbId: widget.tmdbId, mediaType: widget.mediaType),
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        if (results.isEmpty) return const SizedBox();

        return Column(
          children: [
            ...results.map((result) {
              final personId = result['person_id'] as int? ?? 0;
              final characterName = result['character_name'] as String? ?? 'Unknown';
              final percentage = result['percentage'] as int? ?? 0;
              final isUserVote = personId == votedPersonId;
              dynamic person;
              for (final p in widget.cast) {
                if (p.id == personId) { person = p; break; }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUserVote ? AppColors.electricPurple : AppColors.border(context),
                            width: isUserVote ? 2 : 1,
                          ),
                          image: person?.profileUrl != null
                              ? DecorationImage(image: CachedNetworkImageProvider(person!.profileUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: person?.profileUrl == null
                            ? Icon(Icons.person, color: AppColors.textMuted(context), size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    person?.name ?? 'Unknown',
                                    style: TextStyle(
                                      color: AppColors.text(context),
                                      fontWeight: isUserVote ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isUserVote)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.electricPurple.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Your vote', style: TextStyle(color: AppColors.electricPurple, fontSize: 10)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(characterName, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Percentage bar
                      SizedBox(
                        width: 50,
                        child: Column(
                          children: [
                            Text('$percentage%', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: AppColors.border(context),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isUserVote ? AppColors.electricPurple : AppColors.primary,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Change Vote button
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // Delete current vote and show voting UI again
                final userId = supabase.currentUser?.id;
                if (userId != null) {
                  supabase.removeFavoriteActorVote(userId: userId, tmdbId: widget.tmdbId, mediaType: widget.mediaType).then((_) {
                    if (context.mounted) _refreshVotes();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.electricPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.electricPurple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: AppColors.electricPurple, size: 14),
                    const SizedBox(width: 6),
                    Text('Change Vote', style: TextStyle(color: AppColors.electricPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
