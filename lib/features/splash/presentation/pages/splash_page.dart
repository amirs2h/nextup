import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // Wait for animation + auth state to be determined
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (!mounted) return;

      if (!isOnboardingComplete) {
        context.go('/onboarding');
        return;
      }

      // Wait for auth state to be determined (not AuthInitial)
      final authCubit = context.read<AuthCubit>();
      if (authCubit.state is AuthInitial) {
        // Wait for auth state to settle with timeout
        try {
          await for (final state in authCubit.stream.timeout(
            const Duration(seconds: 10),
            onTimeout: (sink) {
              sink.add(AuthUnauthenticated());
            },
          )) {
            if (!mounted) return;
            if (state is! AuthInitial) {
              if (state is AuthAuthenticated) {
                context.go('/');
              } else {
                context.go('/login');
              }
              break;
            }
          }
        } catch (e) {
          if (mounted) context.go('/login');
        }
      } else {
        // Auth state already determined
        if (authCubit.state is AuthAuthenticated) {
          context.go('/');
        } else {
          context.go('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 60,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'NextUp',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your shows & movies',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
