import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';

Future<void> initializeFirebase() async {
  AppConfig.gate;
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  const domain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  if (apiKey.isNotEmpty) {
    if (appId.isEmpty ||
        senderId.isEmpty ||
        projectId.isEmpty ||
        bucket.isEmpty) {
      throw StateError('Firebase 앱 설정을 모두 입력해 주세요.');
    }
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        storageBucket: bucket,
        authDomain: domain == '' ? null : domain,
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  if (const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
    const configuredHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
    final host = configuredHost.isNotEmpty
        ? configuredHost
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFunctions.instanceFor(region: 'asia-northeast3')
        .useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}
