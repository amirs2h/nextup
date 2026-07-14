import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';

class PwaInstallPrompt extends StatefulWidget {
  final Widget child;
  const PwaInstallPrompt({super.key, required this.child});

  @override
  State<PwaInstallPrompt> createState() => _PwaInstallPromptState();
}

class _PwaInstallPromptState extends State<PwaInstallPrompt> {
  bool _showPrompt = false;
  bool _isIOS = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    if (!kIsWeb) return;

    // Check if iOS
    final userAgent = _getUserAgent();
    final isIOS = userAgent.contains('iPhone') || userAgent.contains('iPad') || userAgent.contains('iPod');
    
    if (!isIOS) return;

    // Check if already dismissed
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('pwa_install_dismissed') ?? false;
    
    if (!dismissed && mounted) {
      // Show after a small delay for better UX
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _showPrompt = true;
          _isIOS = true;
        });
      }
    }
  }

  String _getUserAgent() {
    try {
      // ignore: undefined_prefixed_name
      return const String.fromEnvironment('USER_AGENT', defaultValue: '');
    } catch (e) {
      return '';
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pwa_install_dismissed', true);
    if (mounted) {
      setState(() => _showPrompt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showPrompt)
          _buildOverlay(context),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _LiquidGlassCard(
              onDismiss: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassCard extends StatelessWidget {
  final VoidCallback onDismiss;
  
  const _LiquidGlassCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
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
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'نصب NextUp',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'تجربه بهتر با نصب روی Home Screen',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Steps
              _buildStep('۱', 'روی Share بزن', Icons.ios_share_rounded),
              const SizedBox(height: 12),
              _buildStep('۲', 'Add to Home Screen رو انتخاب کن', Icons.add_circle_outline_rounded),
              const SizedBox(height: 28),
              
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
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      child: Text(
                        'بعداً',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'متوجه شدم',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
          ),
        ),
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 22),
      ],
    );
  }
}
