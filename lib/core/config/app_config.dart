class AppConfig {
  // TMDB API
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '17dc9b5c7bedf50c8146220be73d8a50');
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  static const String tmdbPosterSize = '/w500';
  static const String tmdbBackdropSize = '/original';
  static const String tmdbProfileSize = '/w185';

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
}
