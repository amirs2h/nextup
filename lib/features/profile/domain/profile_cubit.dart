import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class ProfileState {}

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
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final SupabaseService _supabaseService;

  ProfileCubit(this._supabaseService) : super(ProfileInitial());

  Future<void> loadProfile(String userId) async {
    emit(ProfileLoading());
    try {
      final profile = await _supabaseService.getProfile(userId);

      // Get counts
      final watchlist = await _supabaseService.getWatchlist(userId: userId);
      final followersData = await _supabaseService.getFollowers(userId);
      final followingData = await _supabaseService.getFollowing(userId);

      emit(ProfileLoaded(
        profile: profile,
        followersCount: followersData.length,
        followingCount: followingData.length,
        watchlistCount: watchlist.length,
        followers: followersData,
        following: followingData,
      ));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> loadFollowers(String userId) async {
    try {
      final followersData = await _supabaseService.getFollowers(userId);
      if (state is ProfileLoaded) {
        final current = state as ProfileLoaded;
        emit(ProfileLoaded(
          profile: current.profile,
          followersCount: current.followersCount,
          followingCount: current.followingCount,
          watchlistCount: current.watchlistCount,
          followers: followersData,
          following: current.following,
        ));
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> loadFollowing(String userId) async {
    try {
      final followingData = await _supabaseService.getFollowing(userId);
      if (state is ProfileLoaded) {
        final current = state as ProfileLoaded;
        emit(ProfileLoaded(
          profile: current.profile,
          followersCount: current.followersCount,
          followingCount: current.followingCount,
          watchlistCount: current.watchlistCount,
          followers: current.followers,
          following: followingData,
        ));
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> followUser(String followerId, String followingId) async {
    try {
      await _supabaseService.followUser(followerId, followingId);
      await loadProfile(followerId);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      await _supabaseService.unfollowUser(followerId, followingId);
      await loadProfile(followerId);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
