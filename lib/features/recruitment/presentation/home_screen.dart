import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config.dart';
import '../../../core/errors.dart';
import '../../../core/theme.dart';
import '../data/repository.dart';
import '../domain/recruitment.dart';
import 'create_screen.dart';
import 'detail_screen.dart';
import 'chat_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});
  final RecruitmentRepository repository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0, _radius = 1000;
  bool _busy = false,
      _current = false,
      _owned = true,
      _locating = false,
      _signingOut = false;
  String? _error, _locationNote;
  String _status = 'all';
  LatLng _center = AppConfig.gate;
  List<Recruitment> _items = [];
  final List<({String id, String text})> _notices = [];
  final _scrolls = List.generate(4, (_) => ScrollController());
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final s in _scrolls) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // A service-area snapshot also keeps My posts independent of the search radius.
      final result = await widget.repository
          .list(AppConfig.gate, 2000)
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _items = result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _items = [];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _detail(Recruitment item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          repository: widget.repository,
          id: item.id,
          center: _center,
          onChanged: (r) {
            _notices.insert(0, (id: r.id, text: '${r.product} · ${r.label}'));
          },
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _create() async {
    final created = await Navigator.push<Recruitment>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateScreen(repository: widget.repository),
      ),
    );
    if (!mounted) return;
    if (created != null) {
      setState(() {
        _tab = 1;
        _owned = true;
        _status = 'all';
        _notices.insert(0, (
          id: created.id,
          text: '${created.product} · 모집을 등록했어요',
        ));
      });
    }
    await _load();
  }

  Future<void> _location() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('위치 권한이 없어요.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _center = LatLng(p.latitude, p.longitude);
        _current = true;
        _locationNote = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _center = AppConfig.gate;
          _current = false;
          _locationNote = '위치를 가져오지 못해 정문 기준으로 보여드려요. 위치 권한과 연결을 확인해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
    if (mounted) await _load();
  }

  Future<void> _basis() async {
    final choice = await appSheet<String>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '어디를 기준으로 볼까요?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            '선택한 위치에서의 직선거리로 표시해요.\n모집은 정문 반경 2km 안에서만 조회돼요.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'current'),
            icon: const Icon(Icons.my_location),
            label: const Text('현재 위치 기준'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, 'gate'),
            icon: const Icon(Icons.school_outlined),
            label: Text('${AppConfig.gateName} 기준'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'current') {
      await _location();
    } else {
      setState(() {
        _center = AppConfig.gate;
        _current = false;
        _locationNote = null;
      });
      await _load();
    }
  }

  Future<void> _notifications() async {
    final id = await appSheet<String>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '알림',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (_notices.isEmpty)
            const EmptyState(
              title: '새 알림이 없어요',
              message: '앱에서 확인한 모집 상태가 여기에 표시돼요.',
              icon: Icons.notifications_none,
            ),
          for (final n in _notices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(n.text),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, n.id),
            ),
          const Notice(
            '앱을 사용하는 동안 확인한 알림이에요. 푸시 알림은 Firebase 연결 후 별도 설정이 필요해요.',
          ),
        ],
      ),
    );
    if (!mounted || id == null) return;
    setState(() => _tab = 0);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          repository: widget.repository,
          id: id,
          center: _center,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _back() async {
    if (_tab != 0) {
      setState(() => _tab = 0);
      return;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('앱을 종료할까요?'),
        content: Text(
          widget.repository.isDemo
              ? '시연 계정과 데이터는 앱을 종료하면 사라져요.'
              : '다음에 또 함께 나눠요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('계속 둘러보기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('종료'),
          ),
        ],
      ),
    );
    if (exit == true) await SystemNavigator.pop();
  }

  Widget _list(
    List<Recruitment> items, {
    required int index,
    required String emptyTitle,
    required String emptyMessage,
    Widget? header,
  }) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      controller: _scrolls[index],
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        ?header,
        if (_busy)
          ...List.generate(
            2,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                child: SizedBox(
                  height: 150,
                  child: Center(child: BusyLabel('모집을 불러오는 중')),
                ),
              ),
            ),
          ),
        if (_error != null) ...[
          Notice(_error!, error: true),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 불러오기'),
          ),
        ] else if (!_busy && items.isEmpty)
          EmptyState(
            title: emptyTitle,
            message: emptyMessage,
            action: TextButton(
              onPressed: _tab == 0 ? _create : () => setState(() => _tab = 0),
              child: Text(_tab == 0 ? '첫 모집 만들기' : '주변 모집 둘러보기'),
            ),
          )
        else if (!_busy)
          for (final r in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecruitmentCard(
                repository: widget.repository,
                item: r,
                distance: meters(_center, r.point).round(),
                onTap: () => _detail(r),
              ),
            ),
      ],
    ),
  );
  Widget _nearby() {
    final visible =
        _items.where((r) => meters(_center, r.point) <= _radius).toList()..sort(
          (a, b) =>
              meters(_center, a.point).compareTo(meters(_center, b.point)),
        );
    final header = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _locating ? null : _basis,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            icon: Icon(
              _current ? Icons.my_location : Icons.location_on_outlined,
              size: 16,
            ),
            label: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _locating
                      ? '위치 확인 중'
                      : _current
                      ? '현재 위치 기준'
                      : '${AppConfig.gateName} 기준',
                  style: const TextStyle(fontSize: 12),
                ),
                const Icon(Icons.expand_more, size: 16),
              ],
            ),
          ),
          const Text(
            '필요한 만큼,\n가까운 이웃과.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '대용량 장보기의 부담을 나눠요.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final r in [500, 1000, 2000])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: r == 2000 ? 0 : 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        backgroundColor: _radius == r
                            ? AppColors.ink
                            : Theme.of(context).colorScheme.surface,
                        foregroundColor: _radius == r
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        side: BorderSide(
                          color: _radius == r
                              ? AppColors.ink
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      onPressed: _busy
                          ? null
                          : () => setState(() => _radius = r),
                      child: Text(r == 500 ? '500m' : '${r ~/ 1000}km'),
                    ),
                  ),
                ),
            ],
          ),
          if (_locationNote != null) ...[
            const SizedBox(height: 12),
            Notice(_locationNote!),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '가까운 모집 ${_busy ? '' : visible.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '가까운 순 · 직선거리',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: '새로고침',
                onPressed: _busy ? null : _load,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _list(
            visible,
            header: header,
            index: 0,
            emptyTitle: '아직 가까운 모집이 없어요',
            emptyMessage: '검색 반경을 넓히거나\n함께 나눌 첫 모집을 열어보세요.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy || _error != null ? null : _create,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('모집 만들기'),
          ),
        ),
      ],
    );
  }

  Widget _mine() {
    final mine = _items
        .where(
          (r) =>
              (_owned
                  ? r.ownerId == widget.repository.uid
                  : r.ownerId != widget.repository.uid &&
                        r.members.contains(widget.repository.uid)) &&
              (_status == 'all' || r.status == _status),
        )
        .toList();
    final header = Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '함께 나누는 장보기',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('내가 연 모집'),
                selected: _owned,
                onSelected: (_) => setState(() => _owned = true),
              ),
              ChoiceChip(
                label: const Text('참여한 모집'),
                selected: !_owned,
                onSelected: (_) => setState(() => _owned = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in [
                ('all', '전체'),
                ('open', '모집 중'),
                ('matched', '매칭 완료'),
                ('cancelled', '모집 취소'),
              ])
                ChoiceChip(
                  label: Text(f.$2),
                  selected: _status == f.$1,
                  onSelected: (_) => setState(() => _status = f.$1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '정문 2km 서비스 지역의 내 모집 전체',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _list(
            mine,
            header: header,
            index: 1,
            emptyTitle: _owned ? '아직 연 모집이 없어요' : '아직 참여한 모집이 없어요',
            emptyMessage: _owned
                ? '필요한 물건이 있나요?\n이웃과 함께 구매할 사람을 찾아보세요.'
                : '주변 모집에서 함께 나눌 물건을 찾아보세요.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: FilledButton.icon(
            onPressed: _busy || _error != null ? null : _create,
            icon: const Icon(Icons.add),
            label: const Text('새 모집 만들기'),
          ),
        ),
      ],
    );
  }

  Widget _chats() {
    final chats = _items
        .where(
          (r) =>
              r.status == 'matched' &&
              r.members.contains(widget.repository.uid),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scrolls[2],
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '이웃과 나누는 이야기',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text('매칭이 완료되면 수령 약속을 정할 수 있어요.'),
          const SizedBox(height: 24),
          if (_busy)
            const Center(child: BusyLabel('채팅 목록 확인 중'))
          else if (_error != null)
            Notice(_error!, error: true)
          else if (chats.isEmpty)
            EmptyState(
              title: '아직 열린 채팅이 없어요',
              message: '모집 인원이 모두 모이면\n참여자 채팅이 열려요.',
              icon: Icons.chat_bubble_outline,
              action: TextButton(
                onPressed: () => setState(() => _tab = 0),
                child: const Text('주변 모집 둘러보기'),
              ),
            )
          else
            for (final r in chats)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(repository: widget.repository, id: r.id),
                      ),
                    ),
                    child: SurfaceCard(
                      child: Row(
                        children: [
                          ProductPhoto(
                            repository: widget.repository,
                            path: r.photo,
                            width: 64,
                            height: 64,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.product,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  '${r.members.length}명 · ${r.place}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _profile() => ListView(
    controller: _scrolls[3],
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        '나의 장보기',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 24),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandMark(size: 48),
            const SizedBox(height: 16),
            Text(
              widget.repository.email ?? '로그인한 이웃',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.repository.isDemo ? '시연 계정' : '이메일 계정',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              minVerticalPadding: 16,
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('모집 검색 기준'),
              subtitle: Text(
                _current ? '현재 위치 · 직선거리' : '${AppConfig.gateName} · 직선거리',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _basis,
            ),
            const Divider(height: 1),
            ListTile(
              minVerticalPadding: 16,
              leading: const Icon(Icons.notifications_none),
              title: const Text('알림'),
              subtitle: const Text('앱 내 상태 알림 · 푸시 연결 준비 중'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _notifications,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Notice(
        '이 앱은 함께 구매할 사람을 연결해요. 매칭 완료는 구매·결제 완료가 아니며, 금액을 자동 정산하지 않아요.',
      ),
      if (widget.repository.isDemo) ...[
        const SizedBox(height: 12),
        const Notice('시연 모드 · 계정과 데이터는 앱 실행 중에만 유지돼요. 정문과 모집 위치는 샘플이에요.'),
      ],
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: _signingOut
            ? null
            : () async {
                setState(() => _signingOut = true);
                try {
                  await widget.repository.signOut();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
                  }
                } finally {
                  if (mounted) setState(() => _signingOut = false);
                }
              },
        icon: const Icon(Icons.logout),
        label: Text(_signingOut ? '로그아웃 중' : '로그아웃'),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: _tab == 0
            ? const Row(
                children: [
                  BrandMark(),
                  SizedBox(width: 9),
                  Text(
                    '배고픈 자취생',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              )
            : Text(['주변 모집', '내 모집', '채팅', '마이'][_tab]),
        actions: [
          IconButton(
            tooltip: '알림',
            onPressed: _notifications,
            icon: Badge(
              isLabelVisible: _notices.isNotEmpty,
              smallSize: 6,
              child: const Icon(Icons.notifications_none, size: 22),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              if (widget.repository.isDemo)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        size: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '시연 모드 · 샘플 위치와 모집',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [_nearby(), _mine(), _chats(), _profile()],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (v) {
          setState(() => _tab = v);
          if (!_busy) _load();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '주변 모집',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '내 모집',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    ),
  );
}
