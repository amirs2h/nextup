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
          color: Colors.black54,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () {}, // Prevent dismiss on card tap
                child: _InstallCard(onDismiss: () => setState(() => _visible = false)),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text('Install NextUp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Add to Home Screen for the best experience', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          
          // Steps
          _buildStep(context, '1', 'Tap the Share button', Icons.ios_share_rounded),
          _buildDivider(),
          _buildStep(context, '2', 'Scroll down and tap "Add to Home Screen"', Icons.add_circle_outline_rounded),
          _buildDivider(),
          _buildStep(context, '3', 'Tap "Add" to confirm', Icons.check_circle_outline_rounded),
          const SizedBox(height: 24),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white24),
                    ),
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
    );
  }

  Widget _buildStep(BuildContext context, String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          ),
          Icon(icon, color: Colors.white54, size: 20),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: 1,
        height: 16,
        color: Colors.white24,
      ),
    );
  }
}
