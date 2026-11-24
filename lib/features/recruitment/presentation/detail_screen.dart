import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config.dart';
import '../../../core/errors.dart';
import '../../../core/theme.dart';
import '../data/repository.dart';
import '../domain/recruitment.dart';
import 'chat_screen.dart';
import 'widgets.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.repository,
    required this.id,
    this.center,
    this.onChanged,
  });
  final RecruitmentRepository repository;
  final String id;
  final LatLng? center;
  final ValueChanged<Recruitment>? onChanged;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Recruitment? _item;
  bool _busy = false, _verified = false, _missing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _verified = false;
    });
    try {
      final r = await widget.repository
          .get(widget.id)
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _item = r;
          _verified = true;
          _missing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _missing = isMissing(e);
          if (_missing) _item = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _participate({bool cancel = false}) async {
    final r = _item;
    if (r == null || !_verified || _busy) return;
    final confirmed = await appSheet<bool>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            cancel ? '참여를 취소할까요?' : '함께 나눠볼까요?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            cancel
                ? '취소하면 내 자리가 비워져요.\n모집 중일 때만 다시 참여할 수 있어요.'
                : '참여하면 모집 인원에 내 자리 1개가 추가돼요.',
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.product,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(r.quantity),
                const SizedBox(height: 12),
                Text(
                  '예상 1인 ${won(r.estimate)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${r.members.length}/${r.target}명 · ${r.place}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Notice('참고 금액이며 실제 비용은 참여자끼리 협의해요. 이 앱에서 결제하지 않아요.'),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('confirm-participation'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(cancel ? '참여 취소하기' : '참여 확정하기'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancel ? '계속 참여하기' : '다음에 할게요'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final latest = await widget.repository
          .participate(widget.id, cancel: cancel)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      widget.onChanged?.call(latest);
      setState(() {
        _item = latest;
        _verified = true;
      });
      if (!cancel && latest.status == 'matched') {
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MatchScreen(repository: widget.repository, item: latest),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cancel ? '참여가 취소됐어요.' : '참여했어요. 이웃을 기다려 주세요.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verified = false;
          _error = '${friendlyError(e)}\n최신 상태를 다시 조회한 후 참여 결과를 확인해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final r = _item;
    final joined = r?.members.contains(widget.repository.uid) ?? false;
    final owner = r?.ownerId == widget.repository.uid;
    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _busy) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('처리 결과를 확인하고 있어요. 잠시 기다려 주세요.')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('모집 상세'),
          actions: [
            IconButton(
              tooltip: '최신 상태 새로고침',
              onPressed: _busy ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _missing
                ? EmptyState(
                    title: '이 모집을 찾을 수 없어요',
                    message: '삭제되었거나 더 이상 볼 수 없는 모집이에요.\n목록에서 다른 모집을 확인해 주세요.',
                    icon: Icons.search_off,
                    action: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('목록으로 돌아가기'),
                    ),
                  )
                : r == null
                ? (_busy
                      ? const Center(child: BusyLabel('모집 확인 중'))
                      : EmptyState(
                          title: '모집을 불러오지 못했어요',
                          message: _error ?? '연결을 확인해 주세요.',
                          action: OutlinedButton(
                            onPressed: _load,
                            child: const Text('다시 불러오기'),
                          ),
                        ))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        ProductPhoto(
                          repository: widget.repository,
                          path: r.photo,
                          height: 240,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            StatusTag(r),
                            Text(
                              '직선 ${meters(widget.center ?? AppConfig.gate, r.point).round()}m',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          r.product,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Wrap(
                            spacing: 28,
                            runSpacing: 20,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '예상 1인 비용',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    won(r.estimate),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: AppColors.lime,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '전체 제품 가격',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    won(r.price),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '모집자가 입력한 참고 금액이에요. 실제 비용은 참여자끼리 협의해요.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _row(Icons.inventory_2_outlined, '제품 수량', r.quantity),
                        _row(
                          Icons.people_outline,
                          '목표 인원',
                          '${r.members.length} / ${r.target}명 · 모집자 포함',
                        ),
                        _row(
                          Icons.calendar_month_outlined,
                          '모집 마감',
                          localTime(r.deadline),
                        ),
                        _row(Icons.location_on_outlined, '수령 장소', r.place),
                        const SizedBox(height: 16),
                        const Notice(
                          '채팅은 인원이 모두 모여 매칭이 완료된 후에 열려요. 매칭 완료는 구매·결제 완료를 의미하지 않아요.',
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _verified && !_busy
                              ? () => showParticipants(
                                  context,
                                  r,
                                  widget.repository.uid,
                                )
                              : null,
                          icon: const Icon(Icons.people_outline),
                          label: Text('함께할 이웃 ${r.members.length}명 보기'),
                        ),
                        if (r.status == 'cancelled') ...[
                          const SizedBox(height: 16),
                          const Notice('모집이 취소되어 참여와 채팅을 할 수 없어요.'),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Notice(_error!, error: true),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: r == null
            ? null
            : SafeArea(
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_verified)
                            FilledButton(
                              onPressed: _busy ? null : _load,
                              child: _busy
                                  ? const BusyLabel('최신 상태 확인 중')
                                  : const Text('최신 상태 다시 확인하기'),
                            )
                          else if (r.status == 'matched' && joined)
                            FilledButton.icon(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    repository: widget.repository,
                                    id: r.id,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('참여자 채팅 열기'),
                            )
                          else if (r.status != 'open')
                            FilledButton(
                              onPressed: null,
                              child: Text(
                                r.status == 'matched'
                                    ? '모집이 완료되었어요'
                                    : '취소된 모집이에요',
                              ),
                            )
                          else if (owner)
                            FilledButton(
                              onPressed: null,
                              child: const Text('내가 연 모집 · 이웃을 기다리는 중'),
                            )
                          else if (joined) ...[
                            const Text(
                              '참여 중이에요. 인원이 모이면 채팅이 열려요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _participate(cancel: true),
                              child: _busy
                                  ? const BusyLabel('취소 확인 중')
                                  : const Text('참여 취소'),
                            ),
                          ] else
                            FilledButton(
                              key: const Key('join-recruitment'),
                              onPressed: _busy ? null : () => _participate(),
                              child: _busy
                                  ? const BusyLabel('참여 확인 중')
                                  : const Text('모집에 참여하기  →'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key, required this.repository, required this.item});
  final RecruitmentRepository repository;
  final Recruitment item;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('매칭 완료')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),
            const Center(
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.lime,
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.ink,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              '함께할 이웃이\n모두 모였어요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            const Text('이제 채팅에서 수령 약속을 정해보세요.', textAlign: TextAlign.center),
            const SizedBox(height: 28),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductPhoto(
                    repository: repository,
                    path: item.photo,
                    height: 170,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.product,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('${item.members.length}명 · ${item.place}'),
                  const SizedBox(height: 10),
                  Text(
                    '예상 1인 ${won(item.estimate)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Notice('매칭 완료는 구매 확정이 아니에요. 결제와 수령 방법은 참여자끼리 협의해 주세요.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(repository: repository, id: item.id),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('참여자 채팅으로 이동'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('목록으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  );
}
