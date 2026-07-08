import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'shared/services/supabase_service.dart';
import 'shared/services/tmdb_service.dart';
import 'shared/services/omdb_service.dart';
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
import 'features/shared_lists/domain/shared_lists_cubit.dart';
import 'features/custom_lists/domain/custom_lists_cubit.dart';
import 'features/rankings/domain/rankings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseService = await SupabaseService.initialize();
  final tmdbService = TmdbService();
  final omdbService = OmdbService();

  runApp(NextUpApp(
    supabaseService: supabaseService,
    tmdbService: tmdbService,
    omdbService: omdbService,
  ));
}

class NextUpApp extends StatefulWidget {
  final SupabaseService supabaseService;
  final TmdbService tmdbService;
  final OmdbService omdbService;

  const NextUpApp({
    super.key,
    required this.supabaseService,
    required this.tmdbService,
    required this.omdbService,
  });

  @override
  State<NextUpApp> createState() => _NextUpAppState();
}

class _NextUpAppState extends State<NextUpApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.initialize(AppRouter.router);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.supabaseService),
        RepositoryProvider.value(value: widget.tmdbService),
        RepositoryProvider.value(value: widget.omdbService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthCubit(widget.supabaseService)),
          BlocProvider(create: (context) => HomeCubit(widget.tmdbService)),
          BlocProvider(create: (context) => SearchCubit(widget.tmdbService, widget.supabaseService)),
          BlocProvider(create: (context) => WatchlistCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => DiscoverCubit(widget.tmdbService)),
          BlocProvider(create: (context) => ProfileCubit(widget.supabaseService)),
          BlocProvider(create: (context) => CommentsCubit(widget.supabaseService)),
          BlocProvider(create: (context) => SettingsCubit(widget.tmdbService)),
          BlocProvider(create: (context) => NotificationsCubit(widget.supabaseService)),
          BlocProvider(create: (context) => StatsCubit(widget.supabaseService)),
          BlocProvider(create: (context) => AchievementsCubit(widget.supabaseService)),
          BlocProvider(create: (context) => ActivityCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => CalendarCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => ComingSoonCubit(widget.tmdbService)),
          BlocProvider(create: (context) => FavoritesCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => WatchHistoryCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => RecommendationsCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => SharedListsCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => CustomListsCubit(widget.supabaseService, widget.tmdbService)),
          BlocProvider(create: (context) => RankingsCubit(widget.supabaseService)),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final isRtl = settingsState.locale.languageCode == 'fa';
            return _NotificationListener(
              child: Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: MaterialApp.router(
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationListener extends StatefulWidget {
  final Widget child;

  const _NotificationListener({required this.child});

  @override
  State<_NotificationListener> createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<_NotificationListener> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListener();
    });
  }

  void _setupListener() {
    final authCubit = context.read<AuthCubit>();
    final notificationsCubit = context.read<NotificationsCubit>();

    if (authCubit.state is AuthAuthenticated) {
      notificationsCubit.subscribeToRealtime();
    }

    _authSubscription = authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) {
        notificationsCubit.subscribeToRealtime();
      } else {
        notificationsCubit.unsubscribeFromRealtime();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
