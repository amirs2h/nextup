import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
  final List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home', path: '/'),
    _NavItem(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Search', path: '/search'),
    _NavItem(icon: Icons.explore_rounded, activeIcon: Icons.explore_rounded, label: 'Discover', path: '/discover'),
    _NavItem(icon: Icons.bookmark_rounded, activeIcon: Icons.bookmark_rounded, label: 'Watchlist', path: '/watchlist'),
    _NavItem(icon: Icons.person_rounded, activeIcon: Icons.person_rounded, label: 'Profile', path: '/profile'),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // Check exact match first, then prefix match (except for root '/')
    for (int i = 0; i < _items.length; i++) {
      if (location == _items[i].path) return i;
    }
    // Prefix match for sub-routes (e.g., /profile/settings -> Profile tab)
    for (int i = _items.length - 1; i >= 1; i--) {
      if (location.startsWith('${_items[i].path}/')) return i;
    }
    return 0;
  }

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    context.go(_items[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.06),
                        ]
                      : [
                          Colors.white.withOpacity(0.85),
                          Colors.white.withOpacity(0.7),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: -5,
                ),
              if (isDark)
                BoxShadow(
                  color: AppColors.electricPurple.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 5),
                ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isActive = currentIndex == index;
                    return _buildNavItem(context, item, index, isActive, isDark);
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item, int index, bool isActive, bool isDark) {
    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 18 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.9),
                    AppColors.primaryLight.withOpacity(0.8),
                  ],
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive
                    ? Colors.white
                    : isDark
                        ? Colors.white.withOpacity(0.45)
                        : Colors.black.withOpacity(0.4),
                size: isActive ? 22 : 24,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                child: Text(item.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
