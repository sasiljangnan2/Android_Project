import 'package:flutter/material.dart';

import '../../../core/errors.dart';
import '../../recruitment/data/demo_repository.dart';
import '../../recruitment/data/repository.dart';
import '../../recruitment/presentation/widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});
  final RecruitmentRepository repository;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _register = false, _busy = false, _visible = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _mode(bool register) {
    _form.currentState?.reset();
    setState(() {
      _register = register;
      _error = null;
      _password.clear();
      _confirm.clear();
    });
  }

  Future<void> _submit({bool demo = false}) async {
    if (_busy) return;
    if (demo) {
      _email.text = DemoRepository.demoEmail;
      _password.text = DemoRepository.demoPassword;
    }
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.signIn(
        _email.text.trim(),
        _password.text,
        register: _register,
      );
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_register && !_busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_busy && _register) _mode(false);
    },
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _register
            ? IconButton(
                onPressed: _busy ? null : () => _mode(false),
                tooltip: '로그인으로 돌아가기',
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(size: 62),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _register ? '반가워요!\n함께 나눌 준비됐나요?' : '필요한 만큼,\n가까운 이웃과.',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _register
                          ? '이메일로 간편하게 시작해요.'
                          : '대용량 장보기의 부담을 나눠요.\n배고픈 자취생에서 함께할 이웃을 찾아보세요.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _register ? '회원가입' : '로그인',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const Key('auth-email'),
                      controller: _email,
                      enabled: !_busy,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        hintText: 'name@example.com',
                      ),
                      validator: (v) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v?.trim() ?? '')
                          ? null
                          : '올바른 이메일을 입력해 주세요.',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('auth-password'),
                      controller: _password,
                      enabled: !_busy,
                      obscureText: !_visible,
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      textInputAction: _register
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_register) _submit();
                      },
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: _register ? '6자 이상 입력해 주세요' : null,
                        suffixIcon: IconButton(
                          tooltip: _visible ? '비밀번호 숨기기' : '비밀번호 보기',
                          onPressed: () => setState(() => _visible = !_visible),
                          icon: Icon(
                            _visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? '비밀번호를 입력해 주세요.'
                          : _register && v.length < 6
                          ? '비밀번호는 6자 이상 입력해 주세요.'
                          : null,
                    ),
                    if (_register) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('auth-confirm'),
                        controller: _confirm,
                        enabled: !_busy,
                        obscureText: !_visible,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(labelText: '비밀번호 확인'),
                        validator: (v) => v == _password.text && v!.isNotEmpty
                            ? null
                            : '비밀번호가 일치하지 않아요.',
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Notice(_error!, error: true),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      key: const Key('auth-submit'),
                      onPressed: _busy ? null : () => _submit(),
                      child: _busy
                          ? const BusyLabel('계정 확인 중')
                          : Text(_register ? '가입하고 시작하기' : '로그인'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _busy ? null : () => _mode(!_register),
                      child: Text(
                        _register ? '이미 계정이 있나요? 로그인' : '처음 오셨나요? 회원가입',
                      ),
                    ),
                    if (widget.repository.isDemo) ...[
                      const SizedBox(height: 22),
                      const Notice(
                        '시연 모드 · 가입한 계정과 데이터는 앱을 종료하면 사라져요. 실제 Firebase 계정은 생성되지 않아요.',
                      ),
                      if (!_register)
                        TextButton(
                          key: const Key('demo-login'),
                          onPressed: _busy ? null : () => _submit(demo: true),
                          child: const Text('시연 계정으로 둘러보기'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
