import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class TmdbService {
  late final Dio _dio;

  TmdbService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.tmdbBaseUrl,
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
        'language': 'en-US',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  // Trending Shows
  Future<Map<String, dynamic>> getTrendingShows({int page = 1}) async {
    final response = await _dio.get(
      '/trending/tv/week',
      queryParameters: {'page': page},
    );
    return response.data;
  }

  // Trending Movies
  Future<Map<String, dynamic>> getTrendingMovies({int page = 1}) async {
    final response = await _dio.get(
      '/trending/movie/week',
      queryParameters: {'page': page},
    );
    return response.data;
  }

  // Show Details
  Future<Map<String, dynamic>> getShowDetails(int showId) async {
    final response = await _dio.get('/tv/$showId');
    return response.data;
  }

  // Show Season Details
  Future<Map<String, dynamic>> getShowSeasonDetails(int showId, int seasonNumber) async {
    final response = await _dio.get('/tv/$showId/season/$seasonNumber');
    return response.data;
  }

  // Movie Details
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await _dio.get('/movie/$movieId');
    return response.data;
  }

  // Search
  Future<Map<String, dynamic>> searchMulti(String query, {int page = 1}) async {
    final response = await _dio.get(
      '/search/multi',
      queryParameters: {
        'query': query,
        'page': page,
      },
    );
    return response.data;
  }

  // Search Shows
  Future<Map<String, dynamic>> searchShows(String query, {int page = 1}) async {
    final response = await _dio.get(
      '/search/tv',
      queryParameters: {
        'query': query,
        'page': page,
      },
    );
    return response.data;
  }

  // Search Movies
  Future<Map<String, dynamic>> searchMovies(String query, {int page = 1}) async {
    final response = await _dio.get(
      '/search/movie',
      queryParameters: {
        'query': query,
        'page': page,
      },
    );
    return response.data;
  }

  // Discover Shows
  Future<Map<String, dynamic>> discoverShows({
    int page = 1,
    String? sortBy,
    List<int>? genreIds,
    int? year,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'sort_by': sortBy ?? 'popularity.desc',
    };
    if (genreIds != null && genreIds.isNotEmpty) {
      params['with_genres'] = genreIds.join(',');
    }
    if (year != null) {
      params['first_air_date_year'] = year;
    }
    final response = await _dio.get('/discover/tv', queryParameters: params);
    return response.data;
  }

  // Discover Movies
  Future<Map<String, dynamic>> discoverMovies({
    int page = 1,
    String? sortBy,
    List<int>? genreIds,
    int? year,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'sort_by': sortBy ?? 'popularity.desc',
    };
    if (genreIds != null && genreIds.isNotEmpty) {
      params['with_genres'] = genreIds.join(',');
    }
    if (year != null) {
      params['primary_release_year'] = year;
    }
    final response = await _dio.get('/discover/movie', queryParameters: params);
    return response.data;
  }

  // Show Credits
  Future<Map<String, dynamic>> getShowCredits(int showId) async {
    final response = await _dio.get('/tv/$showId/credits');
    return response.data;
  }

  // Movie Credits
  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    final response = await _dio.get('/movie/$movieId/credits');
    return response.data;
  }

  // Similar Shows
  Future<Map<String, dynamic>> getSimilarShows(int showId, {int page = 1}) async {
    final response = await _dio.get('/tv/$showId/similar', queryParameters: {'page': page});
    return response.data;
  }

  // Similar Movies
  Future<Map<String, dynamic>> getSimilarMovies(int movieId, {int page = 1}) async {
    final response = await _dio.get('/movie/$movieId/similar', queryParameters: {'page': page});
    return response.data;
  }

  // Genres
  Future<Map<String, dynamic>> getShowGenres() async {
    final response = await _dio.get('/genre/tv/list');
    return response.data;
  }

  Future<Map<String, dynamic>> getMovieGenres() async {
    final response = await _dio.get('/genre/movie/list');
    return response.data;
  }

  // Videos / Trailers
  Future<List<Map<String, dynamic>>> getShowVideos(int showId) async {
    final response = await _dio.get('/tv/$showId/videos');
    return List<Map<String, dynamic>>.from(response.data['results'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getMovieVideos(int movieId) async {
    final response = await _dio.get('/movie/$movieId/videos');
    return List<Map<String, dynamic>>.from(response.data['results'] ?? []);
  }

  // Watch Providers
  Future<Map<String, dynamic>> getShowWatchProviders(int showId) async {
    final response = await _dio.get('/tv/$showId/watch/providers');
    return response.data;
  }

  Future<Map<String, dynamic>> getMovieWatchProviders(int movieId) async {
    final response = await _dio.get('/movie/$movieId/watch/providers');
    return response.data;
  }

  // Airing Today
  Future<Map<String, dynamic>> getAiringToday({int page = 1}) async {
    final response = await _dio.get('/tv/airing_today', queryParameters: {'page': page});
    return response.data;
  }

  // Upcoming Movies
  Future<Map<String, dynamic>> getUpcomingMovies({int page = 1}) async {
    final response = await _dio.get('/movie/upcoming', queryParameters: {'page': page});
    return response.data;
  }

  // Person Search
  Future<Map<String, dynamic>> searchPerson(String query, {int page = 1}) async {
    final response = await _dio.get('/search/person', queryParameters: {'query': query, 'page': page});
    return response.data;
  }

  // Person Details
  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final response = await _dio.get('/person/$personId');
    return response.data;
  }

  // Person Credits
  Future<Map<String, dynamic>> getPersonCredits(int personId) async {
    final response = await _dio.get('/person/$personId/combined_credits');
    return response.data;
  }

  // Change language
  void setLanguage(String languageCode) {
    _dio.options.queryParameters['language'] = languageCode == 'fa' ? 'fa-IR' : 'en-US';
  }
}
