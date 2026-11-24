import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config.dart';
import 'core/firebase_bootstrap.dart';
import 'core/theme.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/presentation/authenticated_session.dart';
import 'features/recruitment/data/demo_repository.dart';
import 'features/recruitment/data/firebase_repository.dart';
import 'features/recruitment/data/repository.dart';
import 'features/recruitment/presentation/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RecruitmentRepository? repository;
  String? failure;
  if (AppConfig.live) {
    try {
      await initializeFirebase();
      repository = FirebaseRepository();
    } catch (_) {
      failure = 'Firebase 앱 설정과 실제 대학 정문 좌표를 확인해 주세요. docs/firebase-setup.md에 연결 방법이 있어요.';
    }
  } else {
    repository = DemoRepository();
  }
  runApp(HungryStudentApp(repository: repository, startupError: failure));
}

class HungryStudentApp extends StatelessWidget {
  const HungryStudentApp({
    super.key,
    required this.repository,
    this.startupError,
    this.themeMode = ThemeMode.system,
  });
  final RecruitmentRepository? repository;
  final String? startupError;
  final ThemeMode themeMode;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '배고픈 자취생',
    locale: const Locale('ko', 'KR'),
    supportedLocales: const [Locale('ko', 'KR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    themeMode: themeMode,
    home: startupError != null || repository == null
        ? Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: EmptyState(
                    title: '연결 설정이 필요해요',
                    message: startupError ?? 'Firebase 설정을 확인해 주세요.',
                    icon: Icons.settings_outlined,
                  ),
                ),
              ),
            ),
          )
        : StreamBuilder<String?>(
            stream: repository!.authChanges,
            initialData: repository!.uid,
            builder: (context, snapshot) => snapshot.data == null
                ? AuthScreen(repository: repository!)
                : AuthenticatedSession(
                    key: ValueKey(snapshot.data),
                    repository: repository!,
                  ),
          ),
  );
}
