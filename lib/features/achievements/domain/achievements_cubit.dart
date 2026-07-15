import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requirement;
  final String category;
  final bool isUnlocked;
  final int current;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirement,
    required this.category,
    this.isUnlocked = false,
    this.current = 0,
  });

  double get progress => requirement > 0 ? (current / requirement).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [id, title, description, icon, color, requirement, category, isUnlocked, current];
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

  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

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
      if (isClosed) return;
      emit(AchievementsLoaded(achievements: _getAchievements(0, 0, 0, 0)));
      return;
    }

    if (isClosed) return;
    emit(AchievementsLoading());
    try {
      final results = await Future.wait([
        _supabaseService.getWatchHistory(userId: user.id),
        _supabaseService.getWatchlist(userId: user.id),
      ]);

      final history = results[0] as List<Map<String, dynamic>>;
      final watchlist = results[1] as List<Map<String, dynamic>>;

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

      if (isClosed) return;
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
      // ===== SHOWS =====
      Achievement(id: 'first_show', title: 'First Steps', description: 'Watch your first show', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 1, category: 'shows', isUnlocked: shows >= 1, current: shows),
      Achievement(id: 'show_5', title: 'Show Lover', description: 'Watch 5 shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 5, category: 'shows', isUnlocked: shows >= 5, current: shows),
      Achievement(id: 'show_10', title: 'Show Expert', description: 'Watch 10 shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 10, category: 'shows', isUnlocked: shows >= 10, current: shows),
      Achievement(id: 'show_25', title: 'Show Master', description: 'Watch 25 shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 25, category: 'shows', isUnlocked: shows >= 25, current: shows),
      Achievement(id: 'show_50', title: 'Show Legend', description: 'Watch 50 shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 50, category: 'shows', isUnlocked: shows >= 50, current: shows),
      // ===== MOVIES =====
      Achievement(id: 'first_movie', title: 'Movie Night', description: 'Watch your first movie', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 1, category: 'movies', isUnlocked: movies >= 1, current: movies),
      Achievement(id: 'movie_10', title: 'Movie Buff', description: 'Watch 10 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 10, category: 'movies', isUnlocked: movies >= 10, current: movies),
      Achievement(id: 'movie_25', title: 'Movie Addict', description: 'Watch 25 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 25, category: 'movies', isUnlocked: movies >= 25, current: movies),
      Achievement(id: 'movie_50', title: 'Cinema King', description: 'Watch 50 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 50, category: 'movies', isUnlocked: movies >= 50, current: movies),
      Achievement(id: 'movie_100', title: 'Movie Legend', description: 'Watch 100 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 100, category: 'movies', isUnlocked: movies >= 100, current: movies),
      // ===== EPISODES =====
      Achievement(id: 'episode_10', title: 'Getting Started', description: 'Watch 10 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 10, category: 'episodes', isUnlocked: episodes >= 10, current: episodes),
      Achievement(id: 'episode_50', title: 'Binge Watcher', description: 'Watch 50 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 50, category: 'episodes', isUnlocked: episodes >= 50, current: episodes),
      Achievement(id: 'episode_100', title: 'Binge Master', description: 'Watch 100 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 100, category: 'episodes', isUnlocked: episodes >= 100, current: episodes),
      Achievement(id: 'episode_500', title: 'Binge Legend', description: 'Watch 500 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 500, category: 'episodes', isUnlocked: episodes >= 500, current: episodes),
      Achievement(id: 'episode_1000', title: 'Binge God', description: 'Watch 1000 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 1000, category: 'episodes', isUnlocked: episodes >= 1000, current: episodes),
      // ===== HOURS =====
      Achievement(id: 'hours_10', title: 'Just Started', description: 'Watch 10 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 10, category: 'hours', isUnlocked: hours >= 10, current: hours),
      Achievement(id: 'hours_50', title: 'Regular Viewer', description: 'Watch 50 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 50, category: 'hours', isUnlocked: hours >= 50, current: hours),
      Achievement(id: 'hours_100', title: 'Dedicated Fan', description: 'Watch 100 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 100, category: 'hours', isUnlocked: hours >= 100, current: hours),
      Achievement(id: 'hours_500', title: 'Time Master', description: 'Watch 500 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 500, category: 'hours', isUnlocked: hours >= 500, current: hours),
      Achievement(id: 'hours_1000', title: 'Ultimate Fan', description: 'Watch 1000 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 1000, category: 'hours', isUnlocked: hours >= 1000, current: hours),
    ];
  }
}
