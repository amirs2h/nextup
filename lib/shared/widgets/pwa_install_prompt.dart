import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

// Conditional import for web platform detection
import 'pwa_platform_stub.dart' if (dart.library.html) 'pwa_platform_web.dart';

class PwaInstallPrompt extends StatefulWidget {
  final Widget child;
  const PwaInstallPrompt({super.key, required this.child});

  @override
  State<PwaInstallPrompt> createState() => _PwaInstallPromptState();
}

class _PwaInstallPromptState extends State<PwaInstallPrompt> {
  bool _showOverlay = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    if (!kIsWeb) {
      if (mounted) setState(() => _checked = true);
      return;
    }

    // Only show on iOS Safari (not Android, not desktop)
    final ua = PlatformHelper.userAgent;
    final isIOS = ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod');
    final isAndroid = ua.contains('Android');

    if (!isIOS || isAndroid) {
      if (mounted) setState(() => _checked = true);
      return;
    }

    // Check if already dismissed
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('pwa_install_dismissed') ?? false;

    if (!dismissed && mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _showOverlay = true);
    }
    if (mounted) setState(() => _checked = true);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pwa_install_dismissed', true);
    if (mounted) setState(() => _showOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (_showOverlay) _PwaOverlay(onDismiss: _dismiss),
      ],
    );
  }
}

class _PwaOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _PwaOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {},
                    child: _InstallCard(onDismiss: onDismiss),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstallCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _InstallCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.electricPurple.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 34, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text('Install NextUp', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text('Add to your home screen for quick access', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),

          // Steps
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                _buildStep('1', 'Tap the Share button', Icons.ios_share_rounded, const Color(0xFF00D4FF)),
                const SizedBox(height: 10),
                _buildStep('2', 'Select "Add to Home Screen"', Icons.add_circle_outline_rounded, const Color(0xFF6C63FF)),
                const SizedBox(height: 10),
                _buildStep('3', 'Tap "Add" to confirm', Icons.check_circle_outline_rounded, const Color(0xFF00FF88)),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDismiss,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Later', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Got it', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(number, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Icon(icon, color: color, size: 18),
        ],
      ),
    );
  }
}
