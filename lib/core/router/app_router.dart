import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_colors.dart';
import '../../shared/widgets/app_background.dart';

import '../../features/auth/domain/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/see_all_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/show/presentation/pages/show_detail_page.dart';
import '../../features/show/presentation/pages/season_detail_page.dart';
import '../../features/show/presentation/pages/episode_detail_page.dart';
import '../../features/movie/presentation/pages/movie_detail_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';
import '../../features/shared_lists/presentation/pages/shared_lists_page.dart';
import '../../features/shared_lists/presentation/pages/shared_list_detail_page.dart';
import '../../features/custom_lists/presentation/pages/custom_lists_page.dart';
import '../../features/custom_lists/presentation/pages/custom_list_detail_page.dart';
import '../../features/rankings/presentation/pages/rankings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/comments/presentation/pages/comments_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/statistics/presentation/pages/stats_page.dart';
import '../../features/achievements/presentation/pages/achievements_page.dart';
import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/coming_soon/presentation/pages/coming_soon_page.dart';
import '../../features/filters/presentation/pages/filters_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/person/presentation/pages/person_detail_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/favorites_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/profile/presentation/pages/user_list_page.dart';
import '../../features/profile/presentation/pages/watch_history_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../shared/widgets/main_scaffold.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = context.read<AuthCubit>().state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isAuthRoute) {
        final publicRoutes = ['/', '/search', '/discover'];
        if (publicRoutes.contains(state.matchedLocation)) {
          return null;
        }
        return '/login';
      }

      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (context, state) => const NoTransitionPage(child: HomePage())),
          GoRoute(path: '/search', pageBuilder: (context, state) => const NoTransitionPage(child: SearchPage())),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return NoTransitionPage(child: DiscoverPage(filters: extra));
            },
          ),
          GoRoute(path: '/watchlist', pageBuilder: (context, state) => const NoTransitionPage(child: WatchlistPage())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage())),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(
        path: '/show/:id/season/:seasonNumber/episode/:episodeNumber',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          final seasonNumber = int.tryParse(state.pathParameters['seasonNumber'] ?? '');
          final episodeNumber = int.tryParse(state.pathParameters['episodeNumber'] ?? '');
          if (id == null || seasonNumber == null || episodeNumber == null) return const _ErrorPage();
          return EpisodeDetailPage(showId: id, seasonNumber: seasonNumber, episodeNumber: episodeNumber);
        },
      ),
      GoRoute(
        path: '/show/:id/season/:seasonNumber',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          final seasonNumber = int.tryParse(state.pathParameters['seasonNumber'] ?? '');
          if (id == null || seasonNumber == null) return const _ErrorPage();
          return SeasonDetailPage(showId: id, seasonNumber: seasonNumber);
        },
      ),
      GoRoute(
        path: '/show/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _ErrorPage();
          return ShowDetailPage(showId: id);
        },
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _ErrorPage();
          return MovieDetailPage(movieId: id);
        },
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
      GoRoute(
        path: '/comments',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const _ErrorPage();
          return CommentsPage(
            tmdbId: extra['tmdbId'] ?? 0,
            mediaType: extra['mediaType'] ?? 'tv',
            seasonNumber: extra['seasonNumber'],
            episodeNumber: extra['episodeNumber'],
            title: extra['title'],
            posterPath: extra['posterPath'],
            commentId: extra['commentId'],
          );
        },
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
      GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
      GoRoute(path: '/achievements', builder: (context, state) => const AchievementsPage()),
      GoRoute(path: '/activity', builder: (context, state) => const ActivityPage()),
      GoRoute(path: '/calendar', builder: (context, state) => const CalendarPage()),
      GoRoute(path: '/coming-soon', builder: (context, state) => const ComingSoonPage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/filters', builder: (context, state) => const FiltersPage()),
      GoRoute(
        path: '/person/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _ErrorPage();
          return PersonDetailPage(personId: id);
        },
      ),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfilePage()),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesPage()),
      GoRoute(path: '/watch-history', builder: (context, state) => const WatchHistoryPage()),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: '/user/:userId/list/:listType',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final listType = state.pathParameters['listType']!;
          return UserListPage(userId: userId, listType: listType);
        },
      ),
      GoRoute(
        path: '/see-all',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SeeAllPage(
            title: extra['title'] ?? 'All',
            type: extra['type'] ?? 'trending_shows',
          );
        },
      ),
      GoRoute(path: '/shared-lists', builder: (context, state) => const SharedListsPage()),
      GoRoute(
        path: '/shared-list/:listId',
        builder: (context, state) {
          final listId = state.pathParameters['listId']!;
          final listName = state.extra as String? ?? 'Shared List';
          return SharedListDetailPage(listId: listId, listName: listName);
        },
      ),
      GoRoute(path: '/custom-lists', builder: (context, state) => const CustomListsPage()),
      GoRoute(
        path: '/custom-list/:listId',
        builder: (context, state) {
          final listId = state.pathParameters['listId']!;
          final listName = state.extra as String? ?? 'Custom List';
          return CustomListDetailPage(listId: listId, listName: listName);
        },
      ),
      GoRoute(path: '/rankings', builder: (context, state) => const RankingsPage()),
    ],
  );
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Page not found', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
