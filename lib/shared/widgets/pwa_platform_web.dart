import 'dart:html' as html;

class PlatformHelper {
  static String get userAgent => html.window.navigator.userAgent;
}
