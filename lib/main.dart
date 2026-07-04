import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/services/supabase_service.dart';
import 'shared/services/tmdb_service.dart';
import 'features/auth/domain/auth_cubit.dart';
import 'features/home/domain/home_cubit.dart';
import 'features/search/domain/search_cubit.dart';
import 'features/watchlist/domain/watchlist_cubit.dart';
import 'features/discover/domain/discover_cubit.dart';
import 'features/profile/domain/profile_cubit.dart';
import 'features/comments/domain/comments_cubit.dart';
import 'features/settings/domain/settings_cubit.dart';
import 'features/notifications/domain/notifications_cubit.dart';
import 'features/statistics/domain/stats_cubit.dart';
import 'features/achievements/domain/achievements_cubit.dart';
import 'features/activity/domain/activity_cubit.dart';
import 'features/calendar/domain/calendar_cubit.dart';
import 'features/coming_soon/domain/coming_soon_cubit.dart';
import 'features/profile/domain/favorites_cubit.dart';
import 'features/profile/domain/watch_history_cubit.dart';
import 'features/home/domain/recommendations_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseService = await SupabaseService.initialize();
  final tmdbService = TmdbService();

  runApp(NextUpApp(
    supabaseService: supabaseService,
    tmdbService: tmdbService,
  ));
}

class NextUpApp extends StatelessWidget {
  final SupabaseService supabaseService;
  final TmdbService tmdbService;

  const NextUpApp({
    super.key,
    required this.supabaseService,
    required this.tmdbService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: supabaseService),
        RepositoryProvider.value(value: tmdbService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthCubit(supabaseService)),
          BlocProvider(create: (context) => HomeCubit(tmdbService)),
          BlocProvider(create: (context) => SearchCubit(tmdbService)),
          BlocProvider(create: (context) => WatchlistCubit(supabaseService, tmdbService)),
          BlocProvider(create: (context) => DiscoverCubit(tmdbService)),
          BlocProvider(create: (context) => ProfileCubit(supabaseService)),
          BlocProvider(create: (context) => CommentsCubit(supabaseService)),
          BlocProvider(create: (context) => SettingsCubit()),
          BlocProvider(create: (context) => NotificationsCubit(supabaseService)),
          BlocProvider(create: (context) => StatsCubit(supabaseService)),
          BlocProvider(create: (context) => AchievementsCubit(supabaseService)),
          BlocProvider(create: (context) => ActivityCubit(supabaseService)),
          BlocProvider(create: (context) => CalendarCubit(supabaseService, tmdbService)),
          BlocProvider(create: (context) => ComingSoonCubit(tmdbService)),
          BlocProvider(create: (context) => FavoritesCubit(supabaseService, tmdbService)),
          BlocProvider(create: (context) => WatchHistoryCubit(supabaseService, tmdbService)),
          BlocProvider(create: (context) => RecommendationsCubit(supabaseService, tmdbService)),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            return MaterialApp.router(
              title: 'NextUp',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settingsState.themeMode,
              routerConfig: AppRouter.router,
              locale: settingsState.locale,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('fa', 'IR'),
              ],
            );
          },
        ),
      ),
    );
  }
}
