import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVA_nf_NwnQkE24xisGC5f97x-u5ec8E8',
    appId: '1:560925700799:android:6d2060a6c5c7944d1d8c0a',
    messagingSenderId: '560925700799',
    projectId: 'she-2b713',
    storageBucket: 'she-2b713.firebasestorage.app',
  );
}
