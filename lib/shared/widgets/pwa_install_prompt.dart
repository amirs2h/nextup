import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';

class PwaInstallPrompt extends StatelessWidget {
  final Widget child;
  const PwaInstallPrompt({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _visible = false),
        child: Container(
          color: Colors.black87,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () {},
                  child: _InstallCard(onDismiss: () => setState(() => _visible = false)),
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
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 40, offset: const Offset(0, 20)),
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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('Install NextUp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Add to your home screen for quick access', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
          ),
          
          // Steps
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStep('1', 'Tap the Share button', Icons.ios_share_rounded, const Color(0xFF00D4FF)),
                const SizedBox(height: 12),
                _buildStep('2', 'Select "Add to Home Screen"', Icons.add_circle_outline_rounded, const Color(0xFF6C63FF)),
                const SizedBox(height: 12),
                _buildStep('3', 'Tap "Add" to confirm', Icons.check_circle_outline_rounded, const Color(0xFF00FF88)),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDismiss,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Later', style: TextStyle(color: Colors.white60, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Got it', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(number, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Icon(icon, color: color, size: 20),
        ],
      ),
    );
  }
}
