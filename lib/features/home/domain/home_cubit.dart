import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/services/tmdb_service.dart';

// States
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<ShowModel> trendingShows;
  final List<MovieModel> trendingMovies;
  final List<ShowModel> topRatedShows;

  HomeLoaded({
    required this.trendingShows,
    required this.trendingMovies,
    required this.topRatedShows,
  });

  @override
  List<Object?> get props => [trendingShows, trendingMovies, topRatedShows];
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// Cubit
class HomeCubit extends Cubit<HomeState> {
  final TmdbService _tmdbService;

  HomeCubit(this._tmdbService) : super(HomeInitial()) {
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        _tmdbService.getTrendingShows(),
        _tmdbService.getTrendingMovies(),
        _tmdbService.discoverShows(sortBy: 'vote_average.desc'),
      ]);

      final trendingShows = (results[0]['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();

      final trendingMovies = (results[1]['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      final topRatedShows = (results[2]['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();

      emit(HomeLoaded(
        trendingShows: trendingShows,
        trendingMovies: trendingMovies,
        topRatedShows: topRatedShows,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> refresh() async {
    await loadHomeData();
  }
}
