import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static DeepLinkService? _instance;
  final AppLinks _appLinks = AppLinks();

  DeepLinkService._();

  static DeepLinkService get instance {
    _instance ??= DeepLinkService._();
    return _instance!;
  }

  Future<void> initialize(GoRouter router) async {
    // Handle initial link (app opened from terminated state)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink, router);
      }
    } catch (e) {
      // Silently continue
    }

    // Handle subsequent links (app opened from background)
    _appLinks.uriLinkStream.listen(
      (uri) => _handleLink(uri, router),
      onError: (err) {
        // Silently continue
      },
    );
  }

  void _handleLink(Uri uri, GoRouter router) {
    // Handle custom scheme: nextup://show/123
    if (uri.scheme == 'nextup') {
      _navigateToPath(uri.path, router);
      return;
    }

    // Handle web URLs: https://nextup.app/show/123
    if (uri.host == 'nextup.app' || uri.host == 'www.nextup.app') {
      _navigateToPath(uri.path, router);
      return;
    }
  }

  void _navigateToPath(String path, GoRouter router) {
    if (path.isEmpty || path == '/') {
      router.go('/');
      return;
    }

    // Parse the path and navigate
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      router.go('/');
      return;
    }

    switch (segments[0]) {
      case 'show':
        if (segments.length >= 6 && segments[2] == 'season' && segments[4] == 'episode') {
          router.go('/show/${segments[1]}/season/${segments[3]}/episode/${segments[5]}');
        } else if (segments.length >= 4 && segments[2] == 'season') {
          router.go('/show/${segments[1]}/season/${segments[3]}');
        } else if (segments.length > 1) {
          router.go('/show/${segments[1]}');
        }
        break;
      case 'movie':
        if (segments.length > 1) {
          router.go('/movie/${segments[1]}');
        }
        break;
      case 'person':
        if (segments.length > 1) {
          router.go('/person/${segments[1]}');
        }
        break;
      case 'user':
        if (segments.length > 1) {
          router.go('/user/${segments[1]}');
        }
        break;
      case 'search':
        router.go('/search');
        break;
      case 'discover':
        router.go('/discover');
        break;
      case 'watchlist':
        router.go('/watchlist');
        break;
      case 'profile':
        router.go('/profile');
        break;
      default:
        router.go('/');
    }
  }

  static String generateShowLink(int showId) {
    return 'nextup://show/$showId';
  }

  static String generateEpisodeLink(int showId, int seasonNumber, int episodeNumber) {
    return 'nextup://show/$showId/season/$seasonNumber/episode/$episodeNumber';
  }

  static String generateMovieLink(int movieId) {
    return 'nextup://movie/$movieId';
  }

  static String generateUserLink(String userId) {
    return 'nextup://user/$userId';
  }
}
