import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/person_cubit.dart';

class PersonDetailPage extends StatelessWidget {
  final int personId;

  const PersonDetailPage({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PersonCubit(
        context.read<TmdbService>(),
        personId,
      ),
      child: _PersonDetailView(personId: personId),
    );
  }
}

class _PersonDetailView extends StatefulWidget {
  final int personId;

  const _PersonDetailView({required this.personId});

  @override
  State<_PersonDetailView> createState() => _PersonDetailViewState();
}

class _PersonDetailViewState extends State<_PersonDetailView> {
  final Map<int, Map<String, String?>> _voteResults = {};
  bool _isLoadingVotes = false;

  Future<void> _loadVoteResults() async {
    if (_isLoadingVotes) return;
    if (!mounted) return;
    final state = context.read<PersonCubit>().state;
    if (state is! PersonLoaded) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isLoadingVotes = true);
    final supabase = context.read<SupabaseService>();
    final userId = authState.user.id;

    try {
      for (final credit in state.credits) {
        final tmdbId = credit['id'] as int?;
        final characterName = credit['character'] as String? ?? '';
        if (tmdbId == null || characterName.isEmpty) continue;

        final vote = await supabase.getUserCharacterVote(
          userId: userId,
          personId: widget.personId,
          tmdbId: tmdbId,
          characterName: characterName,
        );
        _voteResults[widget.personId] ??= {};
        _voteResults[widget.personId]!['${tmdbId}_$characterName'] = vote;
      }
    } catch (e) {
      // Non-critical: vote results failure should not crash the page
    } finally {
      if (mounted) setState(() => _isLoadingVotes = false);
    }
  }

  String? _getCurrentVote(int tmdbId, String characterName) {
    return _voteResults[widget.personId]?['${tmdbId}_$characterName'];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PersonCubit, PersonState>(
      listenWhen: (previous, current) => current is PersonLoaded && previous is! PersonLoaded,
      listener: (context, state) => _loadVoteResults(),
      child: BlocBuilder<PersonCubit, PersonState>(
        builder: (context, state) {
          if (state is PersonLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
          }

          if (state is PersonError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                  ],
                ),
              ),
            );
          }

          if (state is! PersonLoaded) return const Scaffold(body: SizedBox());

          final person = state.person;
          final name = person['name'] ?? '';
          final biography = person['biography'] ?? '';
          final birthday = person['birthday'];
          final deathday = person['deathday'];
          final placeOfBirth = person['place_of_birth'];
          final profilePath = person['profile_path'];

          return Scaffold(
            body: AppBackground(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: AppColors.background(context),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (profilePath != null)
                            CachedNetworkImage(
                              imageUrl: AppConfig.getImageUrl(profilePath, size: 'w780'),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[900]!,
                                highlightColor: Colors.grey[800]!,
                                child: Container(color: Colors.grey[900]),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white24)),
                              ),
                            )
                          else
                            Container(
                              color: Colors.grey[900],
                              child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white24)),
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, AppColors.background(context)],
                                stops: const [0.3, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (birthday != null)
                            _buildInfoRow(context, 'Birthday', birthday),
                          if (deathday != null)
                            _buildInfoRow(context, 'Died', deathday),
                          if (placeOfBirth != null)
                            _buildInfoRow(context, 'Birthplace', placeOfBirth),
                          const SizedBox(height: 20),
                          if (biography.isNotEmpty) ...[
                            Text('Biography', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                            const SizedBox(height: 8),
                            Text(biography, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (state.credits.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Known For', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 260,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.credits.length,
                                itemBuilder: (context, index) {
                                  final credit = state.credits[index];
                                  final title = credit['title'] ?? credit['name'] ?? '';
                                  final posterPath = credit['poster_path'];
                                  final mediaType = credit['media_type'] ?? 'movie';
                                  final id = credit['id'] as int?;
                                  final characterName = credit['character'] ?? '';

                                  return GestureDetector(
                                    onTap: () => context.push(mediaType == 'tv' ? '/show/$id' : '/movie/$id'),
                                    child: Container(
                                      width: 130,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: posterPath != null
                                                        ? CachedNetworkImage(
                                                            imageUrl: AppConfig.getImageUrl(posterPath, size: 'w342'),
                                                            fit: BoxFit.cover,
                                                            errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                                                          )
                                                        : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                                                  ),
                                                ),
                                                if (characterName.isNotEmpty)
                                                  Positioned(
                                                    bottom: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                                        gradient: LinearGradient(
                                                          begin: Alignment.bottomCenter,
                                                          end: Alignment.topCenter,
                                                          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                                                        ),
                                                      ),
                                                      child: Text(
                                                        characterName,
                                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          if (characterName.isNotEmpty && widget.personId > 0 && id != null && id > 0)
                                            _buildVoteButtons(context, widget.personId, id, characterName),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.text(context), fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButtons(BuildContext context, int personId, int tmdbId, String characterName) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return const SizedBox();

    final userId = authState.user.id;
    final supabase = context.read<SupabaseService>();
    final currentVote = _getCurrentVote(tmdbId, characterName);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            try {
              if (currentVote == 'up') {
                await supabase.removeCharacterVote(
                  userId: userId,
                  personId: personId,
                  tmdbId: tmdbId,
                  characterName: characterName,
                );
              } else {
                await supabase.voteForCharacter(
                  userId: userId,
                  personId: personId,
                  tmdbId: tmdbId,
                  characterName: characterName,
                  voteType: 'up',
                );
              }
              await _loadVoteResults();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Failed to vote'), backgroundColor: AppColors.error),
                );
              }
            }
          },
          child: Icon(
            currentVote == 'up' ? Icons.thumb_up : Icons.thumb_up_outlined,
            color: currentVote == 'up' ? AppColors.success : AppColors.textMuted(context),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            try {
              if (currentVote == 'down') {
                await supabase.removeCharacterVote(
                  userId: userId,
                  personId: personId,
                  tmdbId: tmdbId,
                  characterName: characterName,
                );
              } else {
                await supabase.voteForCharacter(
                  userId: userId,
                  personId: personId,
                  tmdbId: tmdbId,
                  characterName: characterName,
                  voteType: 'down',
                );
              }
              await _loadVoteResults();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Failed to vote'), backgroundColor: AppColors.error),
                );
              }
            }
          },
          child: Icon(
            currentVote == 'down' ? Icons.thumb_down : Icons.thumb_down_outlined,
            color: currentVote == 'down' ? AppColors.error : AppColors.textMuted(context),
            size: 16,
          ),
        ),
      ],
    );
  }
}














