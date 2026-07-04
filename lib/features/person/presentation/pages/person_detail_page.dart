import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/person_cubit.dart';

class PersonDetailPage extends StatelessWidget {
  final int personId;

  const PersonDetailPage({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PersonCubit(context.read<TmdbService>(), personId),
      child: const _PersonDetailView(),
    );
  }
}

class _PersonDetailView extends StatelessWidget {
  const _PersonDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, state) {
        if (state is PersonLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))));
        }

        if (state is PersonError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
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
                            imageUrl: 'https://image.tmdb.org/t/p/w780$profilePath',
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
                        // Info cards
                        if (birthday != null)
                          _buildInfoRow(context, 'Birthday', birthday),
                        if (deathday != null)
                          _buildInfoRow(context, 'Died', deathday),
                        if (placeOfBirth != null)
                          _buildInfoRow(context, 'Birthplace', placeOfBirth),
                        const SizedBox(height: 20),
                        // Biography
                        if (biography.isNotEmpty) ...[
                          Text('Biography', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          const SizedBox(height: 8),
                          Text(biography, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                ),
                // Known For
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
                                final id = credit['id'];

                                return GestureDetector(
                                  onTap: () => context.push(mediaType == 'tv' ? '/show/$id' : '/movie/$id'),
                                  child: Container(
                                    width: 130,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: posterPath != null
                                                  ? CachedNetworkImage(
                                                      imageUrl: 'https://image.tmdb.org/t/p/w342$posterPath',
                                                      fit: BoxFit.cover,
                                                      errorWidget: (_, __, ___) => Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                                                    )
                                                  : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
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
}
