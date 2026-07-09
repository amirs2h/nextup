import 'package:flutter/services.dart';

mixin ToggleLockMixin {
  bool _isToggling = false;
  bool get isToggling => _isToggling;

  Future<T?> withToggleLock<T>(Future<T> Function() action) async {
    if (_isToggling) return null;
    _isToggling = true;
    HapticFeedback.lightImpact();
    try {
      return await action();
    } finally {
      _isToggling = false;
    }
  }
}
