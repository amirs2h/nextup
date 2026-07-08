import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.pageGradient(context),
          ),
        ),
        child: Stack(
          children: [
            // Ambient orb - purple (top right)
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.electricPurple.withOpacity(isDark ? 0.15 : 0.08),
                      AppColors.electricPurple.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Ambient orb - red (bottom left)
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(isDark ? 0.12 : 0.06),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Ambient orb - blue (center right)
            Positioned(
              top: 300,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonBlue.withOpacity(isDark ? 0.08 : 0.04),
                      AppColors.neonBlue.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            child,
          ],
        ),
      ),
    );
  }
}
