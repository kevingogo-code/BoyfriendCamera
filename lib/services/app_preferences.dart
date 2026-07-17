import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppPreferences {
  static const _onboardingMarker = '.onboarding_complete';

  Future<File> _marker() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_onboardingMarker');
  }

  Future<bool> shouldShowOnboarding() async {
    try {
      return !await (await _marker()).exists();
    } catch (_) {
      return true;
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await (await _marker()).writeAsString('done');
    } catch (_) {
      // Onboarding remains usable even when local persistence is unavailable.
    }
  }
}
