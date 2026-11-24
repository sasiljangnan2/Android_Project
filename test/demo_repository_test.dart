import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hungry_student/core/config.dart';
import 'package:hungry_student/features/recruitment/data/demo_repository.dart';

void main() {
  test('촬영 데이터는 서비스 범위·인원·상태·채팅 권한을 지키고 새 계정과 분리', () async {
    final r = DemoRepository();
    await r.signIn(DemoRepository.demoEmail, DemoRepository.demoPassword);
    final all = await r.list(AppConfig.demoGate, 2000);
    expect(all, hasLength(8));
    expect(all.map((item) => item.status).toSet(), {
      'open',
      'matched',
      'cancelled',
    });
    for (final item in all) {
      expect(meters(AppConfig.demoGate, item.point), lessThanOrEqualTo(2000));
      expect(item.members, contains(item.ownerId));
      expect(item.members.toSet(), hasLength(item.members.length));
      expect(item.members.length, lessThanOrEqualTo(item.target));
      if (item.status == 'matched') {
        expect(item.members, hasLength(item.target));
      } else if (item.status == 'open') {
        expect(item.members.length, lessThan(item.target));
        expect(item.deadline.isAfter(DateTime.now()), isTrue);
      } else {
        expect(item.deadline.isBefore(DateTime.now()), isTrue);
      }
    }
    expect(await r.list(AppConfig.demoGate, 500), hasLength(1));
    expect(await r.list(AppConfig.demoGate, 1000), hasLength(4));
    final mine = all.where((item) => item.ownerId == r.uid).toList();
    expect(mine.map((item) => item.status).toSet(), {
      'open',
      'matched',
      'cancelled',
    });
    final matched = all.firstWhere((item) => item.id == 'demo-matched');
    final messages = await r.messages(matched.id);
    expect(messages.length, greaterThanOrEqualTo(3));
    expect(messages.any((message) => message.uid == r.uid), isTrue);
    expect(messages.any((message) => message.uid != r.uid), isTrue);
    for (var i = 1; i < messages.length; i++) {
      expect(messages[i].at.isBefore(messages[i - 1].at), isFalse);
    }
    await r.signIn('new-viewer@example.com', 'Password123', register: true);
    expect(all.any((item) => item.members.contains(r.uid)), isFalse);
    await expectLater(r.messages(matched.id), throwsStateError);
  });
  test('가입한 계정만 로그인하며 중복 이메일과 잘못된 비밀번호를 거부', () async {
    final r = DemoRepository();
    expect(r.uid, isNull);
    await r.signIn(' First@Example.com ', 'Password123', register: true);
    final uid = r.uid;
    await r.signOut();
    expect(r.uid, isNull);
    await expectLater(r.signIn('first@example.com', 'wrong'), throwsStateError);
    expect(r.uid, isNull);
    await expectLater(
      r.signIn('first@example.com', 'Password123', register: true),
      throwsStateError,
    );
    await r.signIn('first@example.com', 'Password123');
    expect(r.uid, uid);
    await r.signOut();
    await r.signIn('second@example.com', 'Password123', register: true);
    expect(r.uid, isNot(uid));
  });
  test('시연 계정은 새 실행에 보존하지 않음', () async {
    final r = DemoRepository();
    await r.signIn('fresh@example.com', 'Password123', register: true);
    await expectLater(
      DemoRepository().signIn('fresh@example.com', 'Password123'),
      throwsStateError,
    );
  });
  test('등록 재시도·참여 재시도는 한 자리만 사용하고 매칭 후 취소 차단', () async {
    final r = DemoRepository();
    await r.signIn(DemoRepository.demoEmail, DemoRepository.demoPassword);
    final photo = await r.upload('request-one', Uint8List.fromList([1, 2, 3]));
    final data = <String, dynamic>{
      'product': '테스트 제품',
      'quantity': '2봉',
      'price': 4000,
      'estimate': 2000,
      'target': 2,
      'place': '시연 정문',
      'lat': AppConfig.demoGate.latitude,
      'lng': AppConfig.demoGate.longitude,
      'deadline': DateTime.now()
          .add(const Duration(hours: 1))
          .toUtc()
          .toIso8601String(),
      'photo': photo,
    };
    final first = await r.create('request-one', data),
        retry = await r.create('request-one', data);
    expect(first.id, retry.id);
    expect(retry.members, hasLength(1));
    await expectLater(r.participate(first.id, cancel: true), throwsStateError);
    await r.signIn('new@example.com', 'Password123', register: true);
    expect((await r.participate(first.id)).status, 'matched');
    expect((await r.participate(first.id)).members, hasLength(2));
    await expectLater(r.participate(first.id, cancel: true), throwsStateError);
    await r.send(first.id, 'message-one', '안녕하세요');
    await r.send(first.id, 'message-one', '안녕하세요');
    expect(await r.messages(first.id), hasLength(1));
  });
}
