import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/services/tmdb_service.dart';

// States
abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

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

  @override
  List<Object?> get props => [message];
}

// Cubit
class HomeCubit extends Cubit<HomeState> {
  final TmdbService _tmdbService;

  HomeCubit(this._tmdbService) : super(HomeInitial()) {
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    if (isClosed) return;
    emit(HomeLoading());
    try {
      // Each call handles errors independently
      final results = await Future.wait([
        _tmdbService.getTrendingShows().catchError((e) => <String, dynamic>{}),
        _tmdbService.getTrendingMovies().catchError((e) => <String, dynamic>{}),
        _tmdbService.discoverShows(sortBy: 'vote_average.desc').catchError((e) => <String, dynamic>{}),
      ]);

      final trendingShows = (results[0]['results'] as List?)
          ?.map((json) => ShowModel.fromJson(json))
          .toList() ?? [];

      final trendingMovies = (results[1]['results'] as List?)
          ?.map((json) => MovieModel.fromJson(json))
          .toList() ?? [];

      final topRatedShows = (results[2]['results'] as List?)
          ?.map((json) => ShowModel.fromJson(json))
          .toList() ?? [];

      if (isClosed) return;
      emit(HomeLoaded(
        trendingShows: trendingShows,
        trendingMovies: trendingMovies,
        topRatedShows: topRatedShows,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(HomeError('Something went wrong. Please try again.'));
    }
  }

  Future<void> refresh() async {
    await loadHomeData();
  }
}