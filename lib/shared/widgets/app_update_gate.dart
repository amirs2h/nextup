import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_colors.dart';

// Conditional import for web reload
import 'web_reload_stub.dart' if (dart.library.html) 'web_reload_web.dart' as web_reload;

/// Periodically checks version.json so PWA/web users get a reload prompt
/// instead of being stuck on a cached service-worker shell.
class AppUpdateGate extends StatefulWidget {
  final Widget child;
  const AppUpdateGate({super.key, required this.child});

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> with WidgetsBindingObserver {
  bool _updateAvailable = false;
  String? _builtVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<void> _initCheck() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _builtVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _builtVersion = null;
    }
    await _checkForUpdate();
    // Recheck periodically while app is open (web tabs stay open for days)
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 15));
      if (!mounted) return false;
      await _checkForUpdate();
      return mounted;
    });
  }

  Future<void> _checkForUpdate() async {
    if (!kIsWeb) return;
    try {
      final uri = Uri.base.resolve('version.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      // Flutter version.json: { "version": "1.0.1", "build_number": "2", ... }
      final remote = data is Map
          ? '${data['version'] ?? ''}+${data['build_number'] ?? data['buildNumber'] ?? ''}'
          : null;
      if (remote == null || remote == '+' || remote.isEmpty) return;
      final local = _builtVersion;
      if (local != null && local != remote && mounted) {
        setState(() => _updateAvailable = true);
      }
    } catch (_) {
      // offline / blocked — ignore
    }
  }

  void _reload() {
    web_reload.reloadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_updateAvailable)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.electricPurple.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.system_update_rounded, color: AppColors.electricPurple, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'New version available',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Refresh to update — no need to clear cache',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _updateAvailable = false),
                      child: Text('Later', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    ),
                    ElevatedButton(
                      onPressed: _reload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
