import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic>? profile;
  final int followersCount;
  final int followingCount;
  final int watchlistCount;
  final List<Map<String, dynamic>> followers;
  final List<Map<String, dynamic>> following;

  ProfileLoaded({
    this.profile,
    this.followersCount = 0,
    this.followingCount = 0,
    this.watchlistCount = 0,
    this.followers = const [],
    this.following = const [],
  });

  @override
  List<Object?> get props => [profile, followersCount, followingCount, watchlistCount, followers, following];
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final SupabaseService _supabaseService;

  ProfileCubit(this._supabaseService) : super(ProfileInitial());

  Future<void> loadProfile(String userId) async {
    if (isClosed) return;
    emit(ProfileLoading());
    try {
      final profile = await _supabaseService.getProfile(userId);

      // Get counts
      final watchlist = await _supabaseService.getWatchlist(userId: userId);
      final followersData = await _supabaseService.getFollowers(userId);
      final followingData = await _supabaseService.getFollowing(userId);

      if (isClosed) return;
      emit(ProfileLoaded(
        profile: profile,
        followersCount: followersData.length,
        followingCount: followingData.length,
        watchlistCount: watchlist.length,
        followers: followersData,
        following: followingData,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError('Something went wrong. Please try again.'));
    }
  }

  Future<void> loadFollowers(String userId) async {
    try {
      final followersData = await _supabaseService.getFollowers(userId);
      if (state is ProfileLoaded) {
        final current = state as ProfileLoaded;
        if (isClosed) return;
        emit(ProfileLoaded(
          profile: current.profile,
          followersCount: followersData.length,
          followingCount: current.followingCount,
          watchlistCount: current.watchlistCount,
          followers: followersData,
          following: current.following,
        ));
      }
    } catch (e) {
        // Error handled silently
      }
  }

  Future<void> loadFollowing(String userId) async {
    try {
      final followingData = await _supabaseService.getFollowing(userId);
      if (state is ProfileLoaded) {
        final current = state as ProfileLoaded;
        if (isClosed) return;
        emit(ProfileLoaded(
          profile: current.profile,
          followersCount: current.followersCount,
          followingCount: followingData.length,
          watchlistCount: current.watchlistCount,
          followers: current.followers,
          following: followingData,
        ));
      }
    } catch (e) {
        // Error handled silently
      }
  }

  Future<void> followUser(String followerId, String followingId) async {
    try {
      await _supabaseService.followUser(followerId, followingId);
      await loadProfile(followerId);
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError('Something went wrong. Please try again.'));
    }
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      await _supabaseService.unfollowUser(followerId, followingId);
      await loadProfile(followerId);
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError('Something went wrong. Please try again.'));
    }
  }
}