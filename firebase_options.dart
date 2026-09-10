import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured. Run flutterfire configure.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'REPLACE_WITH_FIREBASE_ANDROID_API_KEY',
          appId: 'REPLACE_WITH_FIREBASE_ANDROID_APP_ID',
          messagingSenderId: '684311976233',
          projectId: 'kashmir-vegitable-5ebdb',
          storageBucket: 'kashmir-vegitable-5ebdb.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'REPLACE_WITH_FIREBASE_IOS_API_KEY',
          appId: 'REPLACE_WITH_FIREBASE_IOS_APP_ID',
          messagingSenderId: '684311976233',
          projectId: 'kashmir-vegitable-5ebdb',
          storageBucket: 'kashmir-vegitable-5ebdb.firebasestorage.app',
          iosBundleId: 'com.kashmirvegitable.app',
        );
      default:
        throw UnsupportedError('This platform is not configured.');
    }
  }
}
