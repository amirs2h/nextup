import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final Set<int> _selectedGenres = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _genres = [
    {'id': 28, 'name': 'Action', 'icon': Icons.local_fire_department},
    {'id': 12, 'name': 'Adventure', 'icon': Icons.explore},
    {'id': 16, 'name': 'Animation', 'icon': Icons.mood},
    {'id': 35, 'name': 'Comedy', 'icon': Icons.sentiment_very_satisfied},
    {'id': 80, 'name': 'Crime', 'icon': Icons.gavel},
    {'id': 99, 'name': 'Documentary', 'icon': Icons.movie_creation},
    {'id': 18, 'name': 'Drama', 'icon': Icons.theater_comedy},
    {'id': 10751, 'name': 'Family', 'icon': Icons.family_restroom},
    {'id': 14, 'name': 'Fantasy', 'icon': Icons.auto_awesome},
    {'id': 36, 'name': 'History', 'icon': Icons.history_edu},
    {'id': 27, 'name': 'Horror', 'icon': Icons.sentiment_very_dissatisfied},
    {'id': 10402, 'name': 'Music', 'icon': Icons.music_note},
    {'id': 9648, 'name': 'Mystery', 'icon': Icons.question_mark},
    {'id': 10749, 'name': 'Romance', 'icon': Icons.favorite},
    {'id': 878, 'name': 'Sci-Fi', 'icon': Icons.rocket_launch},
    {'id': 53, 'name': 'Thriller', 'icon': Icons.psychology},
    {'id': 10752, 'name': 'War', 'icon': Icons.shield},
    {'id': 37, 'name': 'Western', 'icon': Icons.landscape},
  ];

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setStringList(
      'favorite_genres',
      _selectedGenres.map((id) => id.toString()).toList(),
    );

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)]),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.movie_outlined, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Welcome to NextUp!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 8),
          Text(
            'Select your favorite genres to get personalized recommendations',
            style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _genres.map((genre) {
          final isSelected = _selectedGenres.contains(genre['id']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedGenres.remove(genre['id']);
                } else {
                  _selectedGenres.add(genre['id']);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)])
                    : null,
                color: isSelected ? null : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border(context),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    genre['icon'],
                    color: isSelected ? Colors.white : AppColors.textMuted(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    genre['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '${_selectedGenres.length} genres selected',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
          ),
          const SizedBox(height: 12),
          GlassButton(
            text: _isLoading ? 'Setting up...' : 'Get Started',
            icon: _isLoading ? null : Icons.arrow_forward_rounded,
            onPressed: _isLoading || _selectedGenres.isEmpty
                ? () {}
                : _completeOnboarding,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_complete', true);
              if (mounted) context.go('/');
            },
            child: Text('Skip for now', style: TextStyle(color: AppColors.textMuted(context))),
          ),
        ],
      ),
    );
  }
}
