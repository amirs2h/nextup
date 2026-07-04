import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final Map<String, dynamic>? profile;
  AuthAuthenticated({required this.user, this.profile});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthEmailConfirmationRequired extends AuthState {
  final String email;
  AuthEmailConfirmationRequired(this.email);
}

class AuthPasswordResetSent extends AuthState {}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final SupabaseService _supabaseService;

  AuthCubit(this._supabaseService) : super(AuthInitial()) {
    _checkAuth();
  }

  void _checkAuth() {
    final user = _supabaseService.currentUser;
    if (user != null) {
      _loadProfile(user);
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _loadProfile(User user) async {
    try {
      // Retry logic for profile loading
      Map<String, dynamic>? profile;
      for (int i = 0; i < 3; i++) {
        profile = await _supabaseService.getProfile(user.id);
        if (profile != null) break;
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
      }
      emit(AuthAuthenticated(user: user, profile: profile));
    } catch (e) {
      emit(AuthAuthenticated(user: user));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _loadProfile(response.user!);
      } else {
        emit(AuthError('Login failed. Please try again.'));
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login')) {
        emit(AuthError('Invalid email or password.'));
      } else {
        emit(AuthError('Login failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    emit(AuthLoading());
    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        username: username,
      );
      if (response.user != null) {
        // Check if email confirmation is required
        if (response.session != null) {
          // User is confirmed, load profile
          await _loadProfile(response.user!);
        } else {
          // Email confirmation required
          emit(AuthEmailConfirmationRequired(email));
        }
      } else {
        emit(AuthError('Registration failed'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _supabaseService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _supabaseService.resetPassword(email);
      emit(AuthPasswordResetSent());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.updateProfile(user.id, data);
      await _loadProfile(user);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> refreshProfile() async {
    final user = _supabaseService.currentUser;
    if (user != null) {
      await _loadProfile(user);
    }
  }
}
