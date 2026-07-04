import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/profile_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadProfile(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is AuthUnauthenticated) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: 80, color: AppColors.textMuted(context)),
                    const SizedBox(height: 16),
                    Text('Please login to view your profile', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 16)),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Login')),
                  ],
                ),
              );
            }

            String username = 'User';
            String email = '';
            if (authState is AuthAuthenticated) {
              username = authState.profile?['username'] ?? 'User';
              email = authState.user.email ?? '';
            }

            return BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                int followersCount = 0;
                int followingCount = 0;
                int watchlistCount = 0;

                if (state is ProfileLoaded) {
                  followersCount = state.followersCount;
                  followingCount = state.followingCount;
                  watchlistCount = state.watchlistCount;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildAvatar(username),
                      const SizedBox(height: 16),
                      Text(username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                      if (email.isNotEmpty) Text(email, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                      const SizedBox(height: 24),
                      _buildStats(context, followersCount, followingCount, watchlistCount),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 24),
                      _buildUserContent(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.settings_outlined, color: AppColors.text(context), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String username) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Center(
        child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildStats(BuildContext context, int followers, int following, int watchlist) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(context, 'Watchlist', watchlist.toString()),
          Container(width: 1, height: 40, color: AppColors.divider(context)),
          _buildStatItem(context, 'Following', following.toString()),
          Container(width: 1, height: 40, color: AppColors.divider(context)),
          _buildStatItem(context, 'Followers', followers.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return GestureDetector(
      onTap: () {
        if (label == 'Following') _showFollowing();
        if (label == 'Followers') _showFollowers();
      },
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            text: 'Edit Profile',
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/edit-profile'),
          ),
        ),
        const SizedBox(width: 12),
        GlassContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: Icon(Icons.share, color: AppColors.text(context)),
        ),
      ],
    );
  }

  Widget _buildUserContent(BuildContext context) {
    return Column(
      children: [
        _buildContentCard(context, icon: Icons.bookmark_outline, title: 'My Watchlist', subtitle: 'Shows and movies to watch', onTap: () => context.go('/watchlist')),
        _buildContentCard(context, icon: Icons.favorite_outline, title: 'Favorites', subtitle: 'Your favorite shows and movies', onTap: () => context.push('/favorites')),
        _buildContentCard(context, icon: Icons.history, title: 'Watch History', subtitle: 'Shows and movies you\'ve watched', onTap: () => context.push('/watch-history')),
        _buildContentCard(context, icon: Icons.bar_chart_outlined, title: 'Statistics', subtitle: 'Your watching stats', onTap: () => context.push('/stats')),
        _buildContentCard(context, icon: Icons.emoji_events_outlined, title: 'Achievements', subtitle: 'Your badges and milestones', onTap: () => context.push('/achievements')),
        _buildContentCard(context, icon: Icons.people_outline, title: 'Activity', subtitle: 'What your friends are watching', onTap: () => context.push('/activity')),
      ],
    );
  }

  Widget _buildContentCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.icon(context), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFollowing() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadFollowing(authState.user.id);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final following = state is ProfileLoaded ? state.following : [];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Following', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 16),
                if (following.isEmpty)
                  Text('Not following anyone yet', style: TextStyle(color: AppColors.textMuted(context)))
                else
                  ...following.map((user) {
                    final username = user['profiles']?['username'] ?? user['username'] ?? 'User';
                    return ListTile(
                      leading: CircleAvatar(child: Text(username[0].toUpperCase())),
                      title: Text(username, style: TextStyle(color: AppColors.text(context))),
                      trailing: TextButton(onPressed: () {}, child: const Text('Unfollow')),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFollowers() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadFollowers(authState.user.id);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final followers = state is ProfileLoaded ? state.followers : [];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Followers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 16),
                if (followers.isEmpty)
                  Text('No followers yet', style: TextStyle(color: AppColors.textMuted(context)))
                else
                  ...followers.map((user) {
                    final username = user['profiles']?['username'] ?? user['username'] ?? 'User';
                    return ListTile(
                      leading: CircleAvatar(child: Text(username[0].toUpperCase())),
                      title: Text(username, style: TextStyle(color: AppColors.text(context))),
                      trailing: TextButton(onPressed: () {}, child: const Text('Follow Back')),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}



