import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web not configured.');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Run flutterfire configure for this platform.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1JuLT34KhbOP6f6lfcV7iwT7mSglqreU',
    appId: '1:622623542542:android:e617f42cd48d1d42d29b5f',
    messagingSenderId: '622623542542',
    projectId: 'coelho-47c23',
    storageBucket: 'coelho-47c23.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkWRfndBg8ldUrE6X8svBbrGo5XQmqKL4',
    appId: '1:622623542542:ios:0479d9980bf62af9d29b5f',
    messagingSenderId: '622623542542',
    projectId: 'coelho-47c23',
    storageBucket: 'coelho-47c23.firebasestorage.app',
    androidClientId: '622623542542-dccsugvq4n68trv2rguas51k0kvgvkia.apps.googleusercontent.com',
    iosClientId: '622623542542-pc2dvn7t62cd7q5n8oh765li9c3dh3pv.apps.googleusercontent.com',
    iosBundleId: 'com.coelho.boxbox',
  );
}
