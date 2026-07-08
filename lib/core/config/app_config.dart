class AppConfig {
  // TMDB API
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '17dc9b5c7bedf50c8146220be73d8a50');
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
  static const String omdbApiKey = String.fromEnvironment('OMDB_API_KEY', defaultValue: 'b10338ed');
  static const String omdbBaseUrl = 'https://www.omdbapi.com';

  // Supabase
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://tnjowttfshtmgirklosh.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_Ip2Eb2vVSuJddFocDoHKGg_HociyHP4');

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
}
