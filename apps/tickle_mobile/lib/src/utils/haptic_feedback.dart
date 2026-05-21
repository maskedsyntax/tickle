import 'package:flutter/services.dart';

class HapticsHelper {
  static Future<void> trigger(String level) async {
    switch (level.toLowerCase()) {
      case 'light':
        await HapticFeedback.lightImpact();
        break;
      case 'medium':
        await HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        await HapticFeedback.heavyImpact();
        break;
      case 'off':
      default:
        // Do nothing
        break;
    }
  }

  static Future<void> selectionClick(String level) async {
    if (level.toLowerCase() == 'off') return;
    await HapticFeedback.selectionClick();
  }
}
