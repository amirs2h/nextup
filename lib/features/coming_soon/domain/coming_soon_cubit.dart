import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

abstract class ComingSoonState {}

class ComingSoonInitial extends ComingSoonState {}

class ComingSoonLoading extends ComingSoonState {}

class ComingSoonLoaded extends ComingSoonState {
  final List<ShowModel> airingToday;
  final List<MovieModel> upcomingMovies;

  ComingSoonLoaded({
    required this.airingToday,
    required this.upcomingMovies,
  });
}

class ComingSoonError extends ComingSoonState {
  final String message;
  ComingSoonError(this.message);
}

class ComingSoonCubit extends Cubit<ComingSoonState> {
  final TmdbService _tmdbService;

  ComingSoonCubit(this._tmdbService) : super(ComingSoonInitial());

  Future<void> loadComingSoon() async {
    emit(ComingSoonLoading());
    try {
      final results = await Future.wait([
        _tmdbService.getAiringToday(),
        _tmdbService.getUpcomingMovies(),
      ]);

      final airingToday = (results[0]['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();

      final upcomingMovies = (results[1]['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      emit(ComingSoonLoaded(
        airingToday: airingToday,
        upcomingMovies: upcomingMovies,
      ));
    } catch (e) {
      emit(ComingSoonError(e.toString()));
    }
  }
}
