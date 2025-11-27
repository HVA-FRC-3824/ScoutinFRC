import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAkfcVtNcyDlW0yiTH2i5rYdmBJ_z1O57M',
    appId: '1:246498824596:web:efc2c0cbc94999559d3f81',
    messagingSenderId: '246498824596',
    projectId: 'firescout3824',
    authDomain: 'firescout3824.firebaseapp.com',
    databaseURL: 'https://firescout3824-default-rtdb.firebaseio.com',
    storageBucket: 'firescout3824.appspot.com',
    measurementId: 'G-7SBQ64VMNP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAH-7YERZcuUO380l57RZ7UqnoRpn2BBpg',
    appId: '1:246498824596:android:8dfca4d44e3937b19d3f81',
    messagingSenderId: '246498824596',
    projectId: 'firescout3824',
    databaseURL: 'https://firescout3824-default-rtdb.firebaseio.com',
    storageBucket: 'firescout3824.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-cr2Lnbx_JWqv49kYWD7usMh6t0I83V8',
    appId: '1:246498824596:ios:68b17ebe7793de469d3f81',
    messagingSenderId: '246498824596',
    projectId: 'firescout3824',
    databaseURL: 'https://firescout3824-default-rtdb.firebaseio.com',
    storageBucket: 'firescout3824.appspot.com',
    iosBundleId: 'com.example.scouting2024',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-cr2Lnbx_JWqv49kYWD7usMh6t0I83V8',
    appId: '1:246498824596:ios:09c4ad35c181c32d9d3f81',
    messagingSenderId: '246498824596',
    projectId: 'firescout3824',
    databaseURL: 'https://firescout3824-default-rtdb.firebaseio.com',
    storageBucket: 'firescout3824.appspot.com',
    iosBundleId: 'com.example.scouting2024.RunnerTests',
  );
}
