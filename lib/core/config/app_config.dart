class AppConfig {
  // TMDB API
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  static const String tmdbPosterSize = '/w500';
  static const String tmdbBackdropSize = '/original';
  static const String tmdbProfileSize = '/w185';

  // TMDB Proxy (Supabase Edge Function - bypasses Iran filter)
  static const String tmdbProxyUrl = '$supabaseUrl/functions/v1/tmdb-proxy';
  static const String imgProxyUrl = '$supabaseUrl/functions/v1/img-proxy';
  static const bool useProxy = true; // Set to false if not in Iran

  // OMDB API (for Rotten Tomatoes ratings)
  static const String omdbApiKey = String.fromEnvironment('OMDB_API_KEY');
  static const String omdbBaseUrl = 'https://www.omdbapi.com';

  // Supabase
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // App
  static const String appName = 'NextUp';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int pageSize = 20;

  // Cache Duration
  static const int cacheDurationHours = 24;

  // Helper: Get image URL (with proxy if needed)
  static String getImageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    return 'https://images.weserv.nl/?url=image.tmdb.org/t/p/$size$path';
  }

  // Validation: Check if all required keys are configured
  static bool get isConfigured =>
      tmdbApiKey.isNotEmpty &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  // Build command:
  // flutter build apk --dart-define=TMDB_API_KEY=xxx --dart-define=OMDB_API_KEY=xxx --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx
}
