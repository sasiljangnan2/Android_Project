import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/config.dart';
import 'features/recruitment/data/demo_repository.dart';
import 'features/recruitment/data/firebase_repository.dart';
import 'features/recruitment/data/repository.dart';
import 'features/recruitment/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? failure;
  if (AppConfig.live) {
    try {
      AppConfig.gate;
      await Firebase.initializeApp();
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    } catch (_) {
      failure = 'Firebase 설정 또는 대학 정문 좌표가 없어요. docs/firebase-setup.md를 확인하세요.';
    }
  }
  runApp(
    HungryStudentApp(
      repository: failure == null && AppConfig.live
          ? FirebaseRepository()
          : DemoRepository(),
      startupError: failure,
    ),
  );
}

class HungryStudentApp extends StatelessWidget {
  const HungryStudentApp({
    super.key,
    required this.repository,
    this.startupError,
  });
  final RecruitmentRepository repository;
  final String? startupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '배고픈 자취생',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff8faf6),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff32724b)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff8faf6),
        centerTitle: false,
      ),
    ),
    home: startupError == null
        ? HomeScreen(repository: repository)
        : Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(startupError!),
              ),
            ),
          ),
  );
}
