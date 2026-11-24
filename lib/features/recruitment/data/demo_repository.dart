import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config.dart';
import '../domain/recruitment.dart';
import 'demo_data.dart';
import 'repository.dart';

/// In-memory demonstration only. Accounts and content reset on process exit.
class DemoRepository implements RecruitmentRepository {
  DemoRepository() {
    _accounts[demoEmail] = _account(demoUserId, demoPassword);
    final now = DateTime.now();
    _items.addAll(demoRecruitments(now));
    _messages.addAll(demoMessages(now));
  }
  static const demoEmail = 'demo@hungry.local', demoPassword = 'Demo1234!';
  final _events = StreamController<String?>.broadcast();
  final Map<String, ({String uid, String salt, String hash})> _accounts = {};
  final Map<String, Map<String, dynamic>> _items = {};
  final Map<String, Map<String, ChatMessage>> _messages = {};
  final Map<String, Uint8List> _photos = {};
  String? _uid, _email;
  @override
  bool get isDemo => true;
  @override
  String? get uid => _uid;
  @override
  String? get email => _email;
  @override
  Stream<String?> get authChanges => _events.stream;
  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
  ({String uid, String salt, String hash}) _account(
    String uid,
    String password,
  ) {
    final salt = const Uuid().v4();
    return (uid: uid, salt: salt, hash: _hash(salt, password));
  }

  @override
  Future<void> signIn(
    String email,
    String password, {
    bool register = false,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      throw StateError('이메일 형식을 확인해 주세요.');
    }
    if (register) {
      if (password.length < 6) throw StateError('비밀번호는 6자 이상 입력해 주세요.');
      if (_accounts.containsKey(normalized)) {
        throw StateError('이미 가입한 이메일이에요. 로그인해 주세요.');
      }
      _accounts[normalized] = _account(const Uuid().v4(), password);
    }
    final account = _accounts[normalized];
    if (account == null || account.hash != _hash(account.salt, password)) {
      throw StateError('이메일 또는 비밀번호를 확인해 주세요.');
    }
    _uid = account.uid;
    _email = normalized;
    _events.add(_uid);
  }

  @override
  Future<void> signOut() async {
    _uid = null;
    _email = null;
    _events.add(null);
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
  Future<List<Recruitment>> list(LatLng center, int radius) async {
    final result = _items.keys
        .map(_find)
        .map(Recruitment.fromJson)
        .where(
          (r) =>
              meters(AppConfig.demoGate, r.point) <= 2000 &&
              meters(center, r.point) <= radius,
        )
        .toList();
    result.sort(
      (a, b) => meters(center, a.point).compareTo(meters(center, b.point)),
    );
    return result;
  }

  @override
  Future<Recruitment> get(String id) async => Recruitment.fromJson(_find(id));
  @override
  Future<Recruitment> create(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    if (uid == null) throw StateError('로그인이 필요해요.');
    final id = '${uid}_$requestId';
    if (!_items.containsKey(id)) {
      if ((data['target'] as int) < 2 ||
          !DateTime.parse(data['deadline'] as String).isAfter(DateTime.now()) ||
          meters(
                AppConfig.demoGate,
                LatLng(data['lat'] as double, data['lng'] as double),
              ) >
              2000 ||
          !_photos.containsKey(data['photo'])) {
        throw StateError('인원·마감·사진·장소를 확인해 주세요.');
      }
      _items[id] = {
        ...data,
        'id': id,
        'ownerId': uid,
        'members': [uid],
        'status': 'open',
      };
    }
    return get(id);
  }

  @override
  Future<Recruitment> participate(String id, {bool cancel = false}) async {
    final j = _find(id),
        members = List<String>.from(_find(id)['members'] as List);
    if (!cancel && members.contains(uid)) return get(id);
    if (j['status'] != 'open') throw StateError('모집 중일 때만 참여·취소할 수 있어요.');
    if (cancel) {
      if (j['ownerId'] == uid) throw StateError('모집자는 참여를 취소할 수 없어요.');
      members.remove(uid);
    } else {
      if (members.length >= (j['target'] as int)) {
        throw StateError('모집 인원이 모두 찼어요.');
      }
      members.add(uid!);
    }
    j['members'] = members;
    if (members.length == j['target']) j['status'] = 'matched';
    return get(id);
  }

  @override
  Future<String> upload(String requestId, Uint8List bytes) async {
    if (uid == null) throw StateError('로그인이 필요해요.');
    final path = 'demoPhotos/$uid/$requestId';
    _photos.putIfAbsent(path, () => Uint8List.fromList(bytes));
    return path;
  }

  @override
  Future<Uint8List?> photo(String path) async => _photos[path];
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
    if (text.trim().isEmpty || text.length > 1000) {
      throw StateError('메시지는 1~1000자로 입력해 주세요.');
    }
    (_messages[id] ??= {}).putIfAbsent(
      requestId,
      () => ChatMessage(uid!, text.trim(), DateTime.now()),
    );
  }
}
