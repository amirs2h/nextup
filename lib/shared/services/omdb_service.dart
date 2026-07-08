import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class OmdbService {
  late final Dio _dio;

  OmdbService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.omdbBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<Map<String, dynamic>?> getRatings(String imdbId) async {
    try {
      if (AppConfig.omdbApiKey.isEmpty) return null;
      final response = await _dio.get('/', queryParameters: {
        'i': imdbId,
        'apikey': AppConfig.omdbApiKey,
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  int? getRottenTomatoesScore(Map<String, dynamic> omdbData) {
    try {
      final ratings = omdbData['Ratings'] as List?;
      if (ratings == null) return null;
      for (final rating in ratings) {
        if (rating['Source'] == 'Rotten Tomatoes') {
          final value = rating['Value'] as String;
          return int.tryParse(value.replaceAll('%', ''));
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String? getImdbRating(Map<String, dynamic> omdbData) {
    try {
      return omdbData['imdbRating'] as String?;
    } catch (e) {
      return null;
    }
  }
}
