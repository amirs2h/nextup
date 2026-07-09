import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final Map<String, dynamic>? profile;
  AuthAuthenticated({required this.user, this.profile});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          runtimeType == other.runtimeType &&
          user.id == other.user.id &&
          profile == other.profile;

  @override
  int get hashCode => Object.hash(user.id, profile);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthEmailConfirmationRequired extends AuthState {
  final String email;
  AuthEmailConfirmationRequired(this.email);

  @override
  List<Object?> get props => [email];
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
      if (isClosed) return;
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
      if (isClosed) return;
      emit(AuthAuthenticated(user: user, profile: profile));
    } catch (e) {
      if (isClosed) return;
      emit(AuthAuthenticated(user: user));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _loadProfile(response.user!);
      } else {
        if (isClosed) return;
        emit(AuthError('Login failed. Please try again.'));
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login')) {
        if (isClosed) return;
        emit(AuthError('Invalid email or password.'));
      } else {
        if (isClosed) return;
        emit(AuthError('Login failed. Please try again.'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> signInWithGoogle() async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final result = await _supabaseService.signInWithGoogle();
      // If result is false, the redirect didn't start
      if (!result) {
        if (isClosed) return;
        emit(AuthUnauthenticated());
      }
      // OAuth redirects, so we don't need to handle the response here
      // The auth state listener will pick up the session
    } catch (e) {
      if (isClosed) return;
      emit(AuthError('Google sign-in failed. Please try again.'));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    if (isClosed) return;
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
          if (isClosed) return;
          emit(AuthEmailConfirmationRequired(email));
        }
      } else {
        if (isClosed) return;
        emit(AuthError('Registration failed'));
      }
    } on AuthException catch (e) {
      if (isClosed) return;
      emit(AuthError(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> signOut() async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      await _supabaseService.signOut();
      if (!isClosed) emit(AuthUnauthenticated());
    } catch (e) {
      if (isClosed) return;
      emit(AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> resetPassword(String email) async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      await _supabaseService.resetPassword(email);
      if (!isClosed) emit(AuthPasswordResetSent());
    } on AuthException catch (e) {
      if (isClosed) return;
      emit(AuthError(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.updateProfile(user.id, data);
      await _loadProfile(user);
    } catch (e) {
      // Don't emit AuthError - keep the authenticated state
      // Just re-load the profile to restore the current state
      await _loadProfile(user);
    }
  }

  Future<void> refreshProfile() async {
    final user = _supabaseService.currentUser;
    if (user != null) {
      await _loadProfile(user);
    }
  }
}