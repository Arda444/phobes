
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDNyEIOEhMRwhU4J3nZPMc5RpduYBM3wVE',
    appId: '1:655373740612:web:682cf396bd2a8e19c2aa11',
    messagingSenderId: '655373740612',
    projectId: 'phobes-d428d',
    authDomain: 'phobes-d428d.firebaseapp.com',
    storageBucket: 'phobes-d428d.firebasestorage.app',
    measurementId: 'G-WJVYGHL7CE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCo8N6FUanfhLpyklu_bVOtXf_jTVeLCTM',
    appId: '1:655373740612:android:358efbefc5d3bf09c2aa11',
    messagingSenderId: '655373740612',
    projectId: 'phobes-d428d',
    storageBucket: 'phobes-d428d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBjIebM_awMUsHgpzej6E2lC_49Sg11ErE',
    appId: '1:655373740612:ios:325afebae57c5fdec2aa11',
    messagingSenderId: '655373740612',
    projectId: 'phobes-d428d',
    storageBucket: 'phobes-d428d.firebasestorage.app',
    androidClientId: '655373740612-ubpisbcadhdcjo3cm2d7g5oqv0n3hd5h.apps.googleusercontent.com',
    iosClientId: '655373740612-ov84a6facgetgtg91ro6nhv1dj2i72b8.apps.googleusercontent.com',
    iosBundleId: 'app.phobes.mobile',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBjIebM_awMUsHgpzej6E2lC_49Sg11ErE',
    appId: '1:655373740612:ios:1e62f950c3345768c2aa11',
    messagingSenderId: '655373740612',
    projectId: 'phobes-d428d',
    storageBucket: 'phobes-d428d.firebasestorage.app',
    androidClientId: '655373740612-ubpisbcadhdcjo3cm2d7g5oqv0n3hd5h.apps.googleusercontent.com',
    iosClientId: '655373740612-ujgvevct5i9qc4h07djp4u40l7hker7a.apps.googleusercontent.com',
    iosBundleId: 'app.phobes.macos',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAmCtalMF4dAMEbF3pjH7kvJBDIOPNLO6c',
    appId: '1:655373740612:web:cdbc7eef6ac669b4c2aa11',
    messagingSenderId: '655373740612',
    projectId: 'phobes-d428d',
    authDomain: 'phobes-d428d.firebaseapp.com',
    storageBucket: 'phobes-d428d.firebasestorage.app',
    measurementId: 'G-0V3YJXTTZK',
  );

}