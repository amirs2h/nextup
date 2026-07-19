import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class TmdbService {
  late final Dio _dio;
  final bool _useProxy;
  String _language = 'en-US';
  
  // Memory cache with eviction
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(hours: 1);
  static const int _maxCacheSize = 200;

  TmdbService({bool? useProxy}) : _useProxy = useProxy ?? AppConfig.useProxy {
    if (_useProxy) {
      _dio = Dio(BaseOptions(
        baseUrl: AppConfig.supabaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'apikey': AppConfig.supabaseAnonKey,
        },
      ));
    } else {
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
  }

  void _evictOldEntries() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((e) => now.difference(e.value) > _cacheDuration)
        .map((e) => e.key)
        .toList();
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    // If still over limit, remove oldest entries
    if (_cache.length > _maxCacheSize) {
      final sortedKeys = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final toRemove = _cache.length - _maxCacheSize;
      for (int i = 0; i < toRemove; i++) {
        _cache.remove(sortedKeys[i].key);
        _cacheTimestamps.remove(sortedKeys[i].key);
      }
    }
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, dynamic>? queryParams]) async {
    final params = queryParams != null ? Map<String, dynamic>.from(queryParams) : <String, dynamic>{};
    
    // No caching for discover/search (filters change)
    final useCache = !path.contains('/discover') && !path.contains('/search');
    
    Map<String, dynamic> data;
    if (_useProxy) {
      params['path'] = path;
      params['language'] = _language;
    }

    final cacheKey = '$path${params.isNotEmpty ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}' : ''}';

    if (useCache) {
      if (_cache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
        final age = DateTime.now().difference(_cacheTimestamps[cacheKey]!);
        if (age < _cacheDuration) {
          return _cache[cacheKey] as Map<String, dynamic>;
        }
        _cache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    try {
      if (_useProxy) {
        final response = await _dio.get('/functions/v1/tmdb-proxy', queryParameters: params);
        data = response.data;
      } else {
        final response = await _dio.get(path, queryParameters: params);
        data = response.data;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Rate limited — wait and retry once
        await Future.delayed(const Duration(seconds: 2));
        try {
          if (_useProxy) {
            final response = await _dio.get('/functions/v1/tmdb-proxy', queryParameters: params);
            data = response.data;
          } else {
            final response = await _dio.get(path, queryParameters: params);
            data = response.data;
          }
        } catch (retryError) {
          throw Exception('TMDB API rate limited. Please try again later.');
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        throw Exception('Failed to load data from TMDB: ${e.message}');
      }
    }

    if (useCache) {
      _cache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = DateTime.now();
      _evictOldEntries();
    }
    
    return data;
  }

  Future<Map<String, dynamic>> getTrendingShows({int page = 1}) async {
    return _get('/trending/tv/week', {'page': page});
  }

  Future<Map<String, dynamic>> getTrendingMovies({int page = 1}) async {
    return _get('/trending/movie/week', {'page': page});
  }

  Future<Map<String, dynamic>> getShowDetails(int showId) async {
    return _get('/tv/$showId');
  }

  Future<Map<String, dynamic>> getShowSeasonDetails(int showId, int seasonNumber) async {
    return _get('/tv/$showId/season/$seasonNumber');
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    return _get('/movie/$movieId');
  }

  Future<Map<String, dynamic>> searchMulti(String query, {int page = 1}) async {
    return _get('/search/multi', {'query': query, 'page': page});
  }

  Future<Map<String, dynamic>> searchShows(String query, {int page = 1}) async {
    return _get('/search/tv', {'query': query, 'page': page});
  }

  Future<Map<String, dynamic>> searchMovies(String query, {int page = 1}) async {
    return _get('/search/movie', {'query': query, 'page': page});
  }

  Future<Map<String, dynamic>> discoverShows({
    int page = 1,
    String? sortBy,
    List<int>? genreIds,
    int? year,
    double? minRating,
    int? showStatus,
    int? voteCountMin,
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
    if (minRating != null && minRating > 0) {
      params['vote_average.gte'] = minRating;
    }
    if (voteCountMin != null && voteCountMin > 0) {
      params['vote_count.gte'] = voteCountMin;
    }
    if (showStatus != null) {
      params['with_status'] = showStatus;
    }
    return _get('/discover/tv', params);
  }

  Future<Map<String, dynamic>> discoverMovies({
    int page = 1,
    String? sortBy,
    List<int>? genreIds,
    int? year,
    double? minRating,
    int? voteCountMin,
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
    if (minRating != null && minRating > 0) {
      params['vote_average.gte'] = minRating;
    }
    if (voteCountMin != null && voteCountMin > 0) {
      params['vote_count.gte'] = voteCountMin;
    }
    return _get('/discover/movie', params);
  }

  Future<Map<String, dynamic>> getShowCredits(int showId) async {
    return _get('/tv/$showId/credits');
  }

  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    return _get('/movie/$movieId/credits');
  }

  Future<Map<String, dynamic>> getSimilarShows(int showId, {int page = 1}) async {
    return _get('/tv/$showId/similar', {'page': page});
  }

  Future<Map<String, dynamic>> getSimilarMovies(int movieId, {int page = 1}) async {
    return _get('/movie/$movieId/similar', {'page': page});
  }

  Future<Map<String, dynamic>> getShowGenres() async {
    return _get('/genre/tv/list');
  }

  Future<Map<String, dynamic>> getMovieGenres() async {
    return _get('/genre/movie/list');
  }

  Future<List<Map<String, dynamic>>> getShowVideos(int showId) async {
    final data = await _get('/tv/$showId/videos');
    return List<Map<String, dynamic>>.from(data['results'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getMovieVideos(int movieId) async {
    final data = await _get('/movie/$movieId/videos');
    return List<Map<String, dynamic>>.from(data['results'] ?? []);
  }

  Future<Map<String, dynamic>> getShowWatchProviders(int showId) async {
    return _get('/tv/$showId/watch/providers');
  }

  Future<Map<String, dynamic>> getMovieWatchProviders(int movieId) async {
    return _get('/movie/$movieId/watch/providers');
  }

  Future<Map<String, dynamic>> getAiringToday({int page = 1}) async {
    return _get('/tv/airing_today', {'page': page});
  }

  Future<Map<String, dynamic>> getUpcomingMovies({int page = 1}) async {
    return _get('/movie/upcoming', {'page': page});
  }

  Future<Map<String, dynamic>> searchPerson(String query, {int page = 1}) async {
    return _get('/search/person', {'query': query, 'page': page});
  }

  Future<Map<String, dynamic>> getCollectionDetails(int collectionId) async {
    return _get('/collection/$collectionId');
  }

  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    return _get('/person/$personId');
  }

  Future<Map<String, dynamic>> getPersonCredits(int personId) async {
    return _get('/person/$personId/combined_credits');
  }

  Future<Map<String, dynamic>> getShowExternalIds(int showId) async {
    return _get('/tv/$showId/external_ids');
  }

  Future<Map<String, dynamic>> getMovieExternalIds(int movieId) async {
    return _get('/movie/$movieId/external_ids');
  }

  Future<Map<String, dynamic>> getShowContentRatings(int showId) async {
    return _get('/tv/$showId/content_ratings');
  }

  Future<Map<String, dynamic>> getMovieReleaseDates(int movieId) async {
    return _get('/movie/$movieId/release_dates');
  }

  Future<Map<String, dynamic>> getShowRecommendations(int showId, {int page = 1}) async {
    return _get('/tv/$showId/recommendations', {'page': page});
  }

  Future<Map<String, dynamic>> getMovieRecommendations(int movieId, {int page = 1}) async {
    return _get('/movie/$movieId/recommendations', {'page': page});
  }

  void setLanguage(String languageCode) {
    _language = languageCode == 'fa' ? 'fa-IR' : 'en-US';
    // Update Dio query parameters for non-proxy mode
    if (!_useProxy) {
      _dio.options.queryParameters['language'] = _language;
    }
    // Invalidate cache when language changes
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
