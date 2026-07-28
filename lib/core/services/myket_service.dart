import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Handles Myket (Iranian app store) intents.
///
/// Uses real Myket deep-link intents (myket://...) that open the Myket app
/// directly rather than a browser. Falls back to the Myket web URL if the
/// Myket app is not installed or the intent cannot be handled.
class MyketService {
  MyketService._();

  /// Application package id — must match android applicationId.
  static const String packageName = 'com.nextup.nextup';

  static const String _webBase = 'https://myket.ir/app';

  /// Open the app's detail page in Myket.
  static Future<bool> openAppPage() {
    return _launch(
      intent: Uri.parse('myket://details?id=$packageName'),
      webFallback: Uri.parse('$_webBase/$packageName'),
    );
  }

  /// Open the comment/review dialog for this app in Myket.
  static Future<bool> openComment() {
    return _launch(
      intent: Uri.parse('myket://comment?id=$packageName'),
      webFallback: Uri.parse('$_webBase/$packageName'),
    );
  }

  /// Open the app download/update page in Myket (used for "check for update").
  static Future<bool> openUpdate() {
    return _launch(
      intent: Uri.parse('myket://download/$packageName'),
      webFallback: Uri.parse('$_webBase/$packageName'),
    );
  }

  /// Try the Myket intent first; on failure fall back to the web URL.
  static Future<bool> _launch({
    required Uri intent,
    required Uri webFallback,
  }) async {
    // On web there is no Myket app — go straight to the web URL.
    if (kIsWeb) {
      return _open(webFallback);
    }
    try {
      if (await canLaunchUrl(intent)) {
        final ok = await launchUrl(intent, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (_) {
      // fall through to web fallback
    }
    return _open(webFallback);
  }

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
