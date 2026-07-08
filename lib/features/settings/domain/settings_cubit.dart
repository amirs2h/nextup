import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/tmdb_service.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool notificationsEnabled;
  final bool emailNotifications;

  SettingsState({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('en'),
    this.notificationsEnabled = true,
    this.emailNotifications = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notificationsEnabled,
    bool? emailNotifications,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          locale == other.locale &&
          notificationsEnabled == other.notificationsEnabled &&
          emailNotifications == other.emailNotifications;

  @override
  int get hashCode => Object.hash(themeMode, locale, notificationsEnabled, emailNotifications);
}

class SettingsCubit extends Cubit<SettingsState> {
  final TmdbService _tmdbService;

  SettingsCubit(this._tmdbService) : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString('themeMode') ?? 'dark';
    final localeStr = prefs.getString('locale') ?? 'en';
    final notifications = prefs.getBool('notifications') ?? true;
    final emailNotifications = prefs.getBool('emailNotifications') ?? false;

    ThemeMode themeMode;
    switch (themeModeStr) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'system':
        themeMode = ThemeMode.system;
        break;
      default:
        themeMode = ThemeMode.dark;
    }

    emit(SettingsState(
      themeMode: themeMode,
      locale: Locale(localeStr),
      notificationsEnabled: notifications,
      emailNotifications: emailNotifications,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    _tmdbService.setLanguage(locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  Future<void> toggleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.notificationsEnabled;
    await prefs.setBool('notifications', newValue);
    emit(state.copyWith(notificationsEnabled: newValue));
  }

  Future<void> toggleEmailNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.emailNotifications;
    await prefs.setBool('emailNotifications', newValue);
    emit(state.copyWith(emailNotifications: newValue));
  }
}
