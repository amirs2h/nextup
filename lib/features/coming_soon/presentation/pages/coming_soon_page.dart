import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/coming_soon_cubit.dart';

class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({super.key});

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage> {
  @override
  void initState() {
    super.initState();
    context.read<ComingSoonCubit>().loadComingSoon();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
          ],
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
            onTap: () => Navigator.pop(context),
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
          Text('Coming Soon', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<ComingSoonCubit, ComingSoonState>(
      builder: (context, state) {
        if (state is ComingSoonLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }

        if (state is ComingSoonError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
              ],
            ),
          );
        }

        if (state is ComingSoonLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.airingToday.isNotEmpty) ...[
                  Text('Airing Today', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 4),
                  Text('New episodes available today', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.airingToday.length,
                      itemBuilder: (context, index) {
                        final show = state.airingToday[index];
                        return ModernShowCard(
                          id: show.id,
                          title: show.name,
                          posterPath: show.posterPath,
                          rating: show.voteAverage,
                          onTap: () => context.push('/show/${show.id}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                if (state.upcomingMovies.isNotEmpty) ...[
                  Text('Upcoming Movies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  const SizedBox(height: 4),
                  Text('Coming to theaters soon', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.upcomingMovies.length,
                      itemBuilder: (context, index) {
                        final movie = state.upcomingMovies[index];
                        return ModernShowCard(
                          id: movie.id,
                          title: movie.title,
                          posterPath: movie.posterPath,
                          rating: movie.voteAverage,
                          isMovie: true,
                          onTap: () => context.push('/movie/${movie.id}'),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}
