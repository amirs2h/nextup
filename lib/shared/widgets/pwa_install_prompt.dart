import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';

class PwaInstallPrompt extends StatelessWidget {
  final Widget child;
  const PwaInstallPrompt({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only show on web, and only once per session
    if (!kIsWeb) return child;
    
    return Stack(
      children: [
        child,
        const _PwaOverlay(),
      ],
    );
  }
}

class _PwaOverlay extends StatefulWidget {
  const _PwaOverlay();

  @override
  State<_PwaOverlay> createState() => _PwaOverlayState();
}

class _PwaOverlayState extends State<_PwaOverlay> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _checkAndShow();
  }

  Future<void> _checkAndShow() async {
    // Small delay for better UX
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    // Always show on web (user can dismiss)
    setState(() => _visible = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _GlassCard(onDismiss: () => setState(() => _visible = false)),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _GlassCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text('Install NextUp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Get the best experience', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text('Later', style: TextStyle(color: Colors.white60)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
