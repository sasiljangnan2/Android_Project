import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../../../core/config.dart';
import '../domain/recruitment.dart';
import 'repository.dart';

class DemoRepository implements RecruitmentRepository {
  DemoRepository() {
    for (var i = 0; i < 3; i++) {
      final p = ['햇반 24개, 같이 나눠요', '계란 한 판 함께 구매해요', '냉동 닭가슴살 공동구매'][i];
      final point = LatLng(
        AppConfig.gate.latitude + 0.002 * (i + 1),
        AppConfig.gate.longitude,
      );
      _items['demo-$i'] = {
        'id': 'demo-$i',
        'product': p,
        'quantity': ['210g × 24개', '30구 × 2판', '1kg × 4봉'][i],
        'price': [24000, 18000, 36000][i],
        'estimate': [6000, 9000, 9000][i],
        'target': [4, 2, 4][i],
        'ownerId': 'demo-owner',
        'members': ['demo-owner'],
        'deadline': DateTime.now()
            .add(const Duration(hours: 24))
            .toUtc()
            .toIso8601String(),
        'place': '시연 수령 장소 ${i + 1}',
        'lat': point.latitude,
        'lng': point.longitude,
        'photo': '',
        'status': 'open',
      };
    }
  }
  final Map<String, Map<String, dynamic>> _items = {};
  final Map<String, Map<String, ChatMessage>> _messages = {};
  @override
  String? uid = 'demo-me';
  @override
  Future<void> signIn(
    String email,
    String password, {
    bool register = false,
  }) async {
    uid = 'demo-me';
  }

  @override
  Future<void> signOut() async {
    uid = null;
  }

  Map<String, dynamic> _find(String id) {
    if (uid == null) throw StateError('로그인이 필요해요.');
    final j = _items[id];
    if (j == null) throw StateError('모집을 찾을 수 없어요.');
    if (j['status'] == 'open' &&
        !DateTime.parse(j['deadline'] as String).isAfter(DateTime.now())) {
      j['status'] = 'cancelled';
    }
    return j;
  }

  @override
  Future<List<Recruitment>> list(LatLng center, int radius) async => _items.keys
      .map(_find)
      .map(Recruitment.fromJson)
      .where(
        (r) =>
            meters(AppConfig.gate, r.point) <= 2000 &&
            meters(center, r.point) <= radius,
      )
      .toList();
  @override
  Future<Recruitment> get(String id) async => Recruitment.fromJson(_find(id));
  @override
  Future<Recruitment> create(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    if (uid == null) throw StateError('로그인이 필요해요.');
    if (!_items.containsKey(requestId)) {
      if ((data['target'] as int) < 2 ||
          !DateTime.parse(data['deadline'] as String).isAfter(DateTime.now()) ||
          meters(
                AppConfig.gate,
                LatLng(data['lat'] as double, data['lng'] as double),
              ) >
              2000) {
        throw StateError('인원·마감·장소를 확인하세요.');
      }
      _items[requestId] = {
        ...data,
        'id': requestId,
        'ownerId': uid,
        'members': [uid],
        'status': 'open',
      };
    }
    return get(requestId);
  }

  @override
  Future<Recruitment> participate(String id, {bool cancel = false}) async {
    final j = _find(id);
    final members = List<String>.from(j['members'] as List);
    if (!cancel && members.contains(uid)) return get(id);
    if (j['status'] != 'open') throw StateError('모집 중일 때만 참여·취소할 수 있어요.');
    if (cancel) {
      if (j['ownerId'] == uid) throw StateError('모집자는 참여를 취소할 수 없어요.');
      members.remove(uid);
    } else {
      members.add(uid!);
    }
    j['members'] = members;
    if (members.length == j['target']) j['status'] = 'matched';
    return get(id);
  }

  @override
  Future<String> upload(String requestId, Uint8List bytes) async =>
      'demo-photo';
  void _chat(String id) {
    final j = _find(id);
    if (j['status'] != 'matched' || !(j['members'] as List).contains(uid)) {
      throw StateError('매칭된 참여자만 채팅할 수 있어요.');
    }
  }

  @override
  Future<List<ChatMessage>> messages(String id) async {
    _chat(id);
    return _messages[id]?.values.toList() ?? [];
  }

  @override
  Future<void> send(String id, String requestId, String text) async {
    _chat(id);
    (_messages[id] ??= {}).putIfAbsent(
      requestId,
      () => ChatMessage(uid!, text, DateTime.now()),
    );
  }
}
