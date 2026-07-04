import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Search', path: '/search'),
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Discover', path: '/discover'),
    _NavItem(icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded, label: 'Watchlist', path: '/watchlist'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', path: '/profile'),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _items.length; i++) {
      if (location == _items[i].path) return i;
    }
    return 0;
  }

  void _onTap(int index) {
    context.go(_items[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 85,
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isActive = currentIndex == index;
                  return GestureDetector(
                    onTap: () => _onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isActive
                            ? const Color(0xFFE50914).withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? const Color(0xFFE50914)
                                : AppColors.textMuted(context),
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFFE50914)
                                  : AppColors.textMuted(context),
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
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
