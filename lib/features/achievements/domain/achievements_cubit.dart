import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requirement;
  final String type; // 'shows', 'movies', 'hours', 'episodes'
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.type,
    this.isUnlocked = false,
  });
}

abstract class AchievementsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AchievementsInitial extends AchievementsState {}

class AchievementsLoading extends AchievementsState {}

class AchievementsLoaded extends AchievementsState {
  final List<Achievement> achievements;
  final int totalShows;
  final int totalMovies;
  final int totalEpisodes;
  final int totalHours;

  AchievementsLoaded({
    required this.achievements,
    this.totalShows = 0,
    this.totalMovies = 0,
    this.totalEpisodes = 0,
    this.totalHours = 0,
  });

  @override
  List<Object?> get props => [achievements, totalShows, totalMovies, totalEpisodes, totalHours];
}

class AchievementsError extends AchievementsState {
  final String message;
  AchievementsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AchievementsCubit extends Cubit<AchievementsState> {
  final SupabaseService _supabaseService;

  AchievementsCubit(this._supabaseService) : super(AchievementsInitial());

  Future<void> loadAchievements() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(AchievementsLoaded(achievements: _getAchievements(0, 0, 0, 0)));
      return;
    }

    emit(AchievementsLoading());
    try {
      final history = await _supabaseService.getWatchHistory(userId: user.id);

      int totalShows = 0;
      int totalMovies = 0;
      int totalEpisodes = 0;
      Set<String> showIds = {};
      Set<String> movieIds = {};

      for (final item in history) {
        if (item['media_type'] == 'tv') {
          showIds.add(item['tmdb_id'].toString());
          if (item['episode_number'] != null) {
            totalEpisodes++;
          }
        } else {
          movieIds.add(item['tmdb_id'].toString());
        }
      }

      totalShows = showIds.length;
      totalMovies = movieIds.length;
      final totalHours = (totalEpisodes * 45 + totalMovies * 120) ~/ 60;

      emit(AchievementsLoaded(
        achievements: _getAchievements(totalShows, totalMovies, totalEpisodes, totalHours),
        totalShows: totalShows,
        totalMovies: totalMovies,
        totalEpisodes: totalEpisodes,
        totalHours: totalHours,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(AchievementsError('Something went wrong. Please try again.'));
    }
  }

  List<Achievement> _getAchievements(int shows, int movies, int episodes, int hours) {
    return [
      Achievement(
        id: 'first_show',
        title: 'First Show',
        description: 'Watch your first show',
        icon: 'ًںژ¬',
        requirement: 1,
        type: 'shows',
        isUnlocked: shows >= 1,
      ),
      Achievement(
        id: 'show_5',
        title: 'Show Enthusiast',
        description: 'Watch 5 different shows',
        icon: 'ًں“؛',
        requirement: 5,
        type: 'shows',
        isUnlocked: shows >= 5,
      ),
      Achievement(
        id: 'show_10',
        title: 'Show Master',
        description: 'Watch 10 different shows',
        icon: 'ًںڈ†',
        requirement: 10,
        type: 'shows',
        isUnlocked: shows >= 10,
      ),
      Achievement(
        id: 'show_25',
        title: 'Show Legend',
        description: 'Watch 25 different shows',
        icon: 'ًں‘‘',
        requirement: 25,
        type: 'shows',
        isUnlocked: shows >= 25,
      ),
      Achievement(
        id: 'first_movie',
        title: 'Movie Night',
        description: 'Watch your first movie',
        icon: 'ًںژ¥',
        requirement: 1,
        type: 'movies',
        isUnlocked: movies >= 1,
      ),
      Achievement(
        id: 'movie_10',
        title: 'Movie Buff',
        description: 'Watch 10 movies',
        icon: 'ًںچ؟',
        requirement: 10,
        type: 'movies',
        isUnlocked: movies >= 10,
      ),
      Achievement(
        id: 'movie_50',
        title: 'Cinema King',
        description: 'Watch 50 movies',
        icon: 'ًںژ­',
        requirement: 50,
        type: 'movies',
        isUnlocked: movies >= 50,
      ),
      Achievement(
        id: 'episode_10',
        title: 'Binge Starter',
        description: 'Watch 10 episodes',
        icon: 'â–¶ï¸ڈ',
        requirement: 10,
        type: 'episodes',
        isUnlocked: episodes >= 10,
      ),
      Achievement(
        id: 'episode_100',
        title: 'Binge Master',
        description: 'Watch 100 episodes',
        icon: 'ًں”¥',
        requirement: 100,
        type: 'episodes',
        isUnlocked: episodes >= 100,
      ),
      Achievement(
        id: 'episode_500',
        title: 'Binge Legend',
        description: 'Watch 500 episodes',
        icon: 'ًں’€',
        requirement: 500,
        type: 'episodes',
        isUnlocked: episodes >= 500,
      ),
      Achievement(
        id: 'hours_10',
        title: 'Getting Started',
        description: 'Watch 10 hours',
        icon: 'âڈ°',
        requirement: 10,
        type: 'hours',
        isUnlocked: hours >= 10,
      ),
      Achievement(
        id: 'hours_100',
        title: 'Dedicated Viewer',
        description: 'Watch 100 hours',
        icon: 'âڈ³',
        requirement: 100,
        type: 'hours',
        isUnlocked: hours >= 100,
      ),
      Achievement(
        id: 'hours_1000',
        title: 'Ultimate Fan',
        description: 'Watch 1000 hours',
        icon: 'ًںŒں',
        requirement: 1000,
        type: 'hours',
        isUnlocked: hours >= 1000,
      ),
    ];
  }
}