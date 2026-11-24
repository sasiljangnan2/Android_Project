import 'package:flutter/material.dart';

import '../../recruitment/data/repository.dart';
import '../../recruitment/presentation/home_screen.dart';

/// Routes belong to the signed-in account and are disposed on sign-out.
class AuthenticatedSession extends StatefulWidget {
  const AuthenticatedSession({super.key, required this.repository});
  final RecruitmentRepository repository;
  @override
  State<AuthenticatedSession> createState() => _AuthenticatedSessionState();
}

class _AuthenticatedSessionState extends State<AuthenticatedSession> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<void>(
    onPopWithResult: (_) => _navigator.currentState?.maybePop(),
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => HomeScreen(repository: widget.repository),
      ),
    ),
  );
}
