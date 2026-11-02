import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config.dart';
import '../data/repository.dart';
import '../domain/recruitment.dart';
import 'create_screen.dart';
import 'detail_screen.dart';

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    return '로그인 정보를 확인하세요. 계정 생성 시 비밀번호는 6자 이상 입력하세요.';
  }
  if (error is FirebaseFunctionsException) {
    return error.message ?? '처리하지 못했어요. 새로고침 후 상태를 확인하세요.';
  }
  if (error is TimeoutException) return '연결을 확인하지 못했어요. 다시 조회한 후 시도하세요.';
  if (error is StateError) return error.message.toString();
  return '연결 또는 설정을 확인하세요. 다시 조회한 후 시도하세요.';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});
  final RecruitmentRepository repository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng center = AppConfig.gate;
  int radius = 1000, tab = 0;
  bool busy = false, current = false;
  String? error;
  List<Recruitment> items = [];
  @override
  void initState() {
    super.initState();
    if (widget.repository.uid != null) _load();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository
          .list(center, radius)
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => items = result);
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _location() async {
    setState(() => busy = true);
    try {
      final p = await (() async {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw StateError('위치 권한 없음');
        }
        return Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 5),
          ),
        );
      })().timeout(const Duration(seconds: 5));
      center = LatLng(p.latitude, p.longitude);
      current = true;
    } catch (_) {
      center = AppConfig.gate;
      current = false;
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.repository.uid == null) {
      return LoginScreen(
        repository: widget.repository,
        onDone: () {
          setState(() {});
          _load();
        },
      );
    }
    final visible = tab == 0
        ? items
        : items
              .where((r) => r.members.contains(widget.repository.uid))
              .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '배고픈 자취생',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: busy
                ? null
                : () async {
                    await widget.repository.signOut();
                    if (mounted) {
                      setState(() {
                        items = [];
                      });
                    }
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!AppConfig.live)
                Container(
                  color: const Color(0xffffedc7),
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    '시연 모드 · 저장은 앱 실행 중에만 유지됩니다. 좌표·모집은 샘플입니다.',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '가까이서 모여,\n가볍게 나눠요.',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${current ? '현재 위치' : AppConfig.gateName} 기준 · 직선거리 · 서비스 지역 2km',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: busy ? null : _location,
                          icon: const Icon(Icons.my_location),
                          label: const Text('현재 위치'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () {
                                  center = AppConfig.gate;
                                  current = false;
                                  _load();
                                },
                          child: const Text('정문 기준'),
                        ),
                      ],
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 500, label: Text('500m')),
                        ButtonSegment(value: 1000, label: Text('1km')),
                        ButtonSegment(value: 2000, label: Text('2km')),
                      ],
                      selected: {radius},
                      onSelectionChanged: busy
                          ? null
                          : (v) {
                              radius = v.first;
                              _load();
                            },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          tab == 0 ? '우리 동네 모집' : '내가 참여한 모집',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: '새로고침',
                          onPressed: busy ? null : _load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    if (tab == 1) const Text('현재 기준점과 반경 안의 참여 모집을 표시해요.'),
                  ],
                ),
              ),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$error\n아래 목록은 이전 조회 결과이며 최신 상태가 아닙니다.',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: visible.isEmpty && !busy
                    ? Center(
                        child: Text(
                          error == null
                              ? '조건에 맞는 모집이 없어요.\n첫 모집을 만들어 볼까요?'
                              : '조회 실패 · 새로고침으로 다시 시도하세요.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final r = visible[index];
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: const Color(0xffe5eee3),
                                  child: Icon(
                                    r.status == 'matched'
                                        ? Icons.check
                                        : Icons.shopping_basket_outlined,
                                    color: const Color(0xff32724b),
                                  ),
                                ),
                                title: Text(
                                  r.product,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${r.label} · ${r.members.length}/${r.target}명\n예상 ${won(r.estimate)} / 1인\n${r.place} · 직선 ${meters(center, r.point).round()}m',
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                isThreeLine: true,
                                onTap: error != null || busy
                                    ? null
                                    : () async {
                                        await Navigator.push<void>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetailScreen(
                                              repository: widget.repository,
                                              id: r.id,
                                            ),
                                          ),
                                        );
                                        if (mounted) _load();
                                      },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy || error != null
            ? null
            : () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateScreen(repository: widget.repository),
                  ),
                );
                if (mounted) _load();
              },
        icon: const Icon(Icons.add),
        label: const Text('모집 만들기'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) {
          setState(() => tab = v);
          _load();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: '동네 모집',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: '내 참여',
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repository,
    required this.onDone,
  });
  final RecruitmentRepository repository;
  final VoidCallback onDone;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit(bool register) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository
          .signIn(email.text.trim(), password.text, register: register)
          .timeout(const Duration(seconds: 5));
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.shopping_basket_outlined,
                size: 64,
                color: Color(0xff32724b),
              ),
              const SizedBox(height: 16),
              const Text(
                '배고픈 자취생',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  '가까운 이웃과 함께 구매할 사람을 찾아요.',
                  textAlign: TextAlign.center,
                ),
              ),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '이메일'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호 (6자 이상)'),
              ),
              const SizedBox(height: 16),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              FilledButton(
                onPressed: busy ? null : () => submit(false),
                child: const Text('로그인'),
              ),
              TextButton(
                onPressed: busy ? null : () => submit(true),
                child: const Text('회원가입'),
              ),
              if (busy) const LinearProgressIndicator(),
              if (!AppConfig.live)
                const Text(
                  '시연 계정으로 진입합니다. 실제 계정을 생성하지 않습니다.',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
