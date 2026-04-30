import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static bool get isSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase options are not configured for web.');
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Firebase options are only configured for Android and iOS.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtQpFT2NYfo2Qq8EEzGMw-uEB-pUXX4bg',
    appId: '1:590878626214:android:45ad7b4d89af22d78b3f67',
    messagingSenderId: '590878626214',
    projectId: 'meal-tracker-analytics',
    storageBucket: 'meal-tracker-analytics.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBnT4nUHSh6Bbq9zpj5OYLg_pkaq3sCHrM',
    appId: '1:590878626214:ios:42ab661a5d0bc48d8b3f67',
    messagingSenderId: '590878626214',
    projectId: 'meal-tracker-analytics',
    storageBucket: 'meal-tracker-analytics.firebasestorage.app',
    iosBundleId: 'by.mealtracker.mealTracker',
  );
}
