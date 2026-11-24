import '../../../core/config.dart';
import '../domain/recruitment.dart';

const demoUserId = 'demo-me';

/// Synthetic recording fixtures. Never used by the Firebase repository.
Map<String, Map<String, dynamic>> demoRecruitments(DateTime now) {
  Map<String, dynamic> item({
    required String id,
    required String product,
    required String quantity,
    required int price,
    required int estimate,
    required int target,
    required List<String> members,
    required int northMeters,
    required int hours,
    required String place,
    String owner = 'demo-owner',
    String status = 'open',
    bool strawberries = false,
  }) => {
    'id': id,
    'product': product,
    'quantity': quantity,
    'price': price,
    'estimate': estimate,
    'target': target,
    'ownerId': owner,
    'members': members,
    'deadline': now.add(Duration(hours: hours)).toUtc().toIso8601String(),
    'place': place,
    'lat': AppConfig.demoGate.latitude + northMeters / 111320,
    'lng': AppConfig.demoGate.longitude,
    'photo':
        'asset:assets/images/${strawberries ? 'strawberries' : 'eggs'}.png',
    'status': status,
  };

  final items = [
    item(
      id: 'demo-0',
      product: '달걀 30구 같이 나눠요',
      quantity: '30구 · 1인 약 10구',
      price: 9900,
      estimate: 3300,
      target: 3,
      members: ['demo-owner', 'demo-neighbor'],
      northMeters: 445,
      hours: 8,
      place: '시연 정문 앞',
    ),
    item(
      id: 'demo-1',
      product: '딸기 1kg 함께 나눠요',
      quantity: '1kg · 1인 약 330g',
      price: 7800,
      estimate: 2600,
      target: 3,
      members: ['demo-owner'],
      northMeters: 712,
      hours: 20,
      place: '시연 학생회관 앞',
      strawberries: true,
    ),
    item(
      id: 'demo-owned-open',
      product: '달걀 40구 나눌 이웃 구해요',
      quantity: '40구 · 1인 약 10구',
      price: 12800,
      estimate: 3200,
      target: 4,
      owner: demoUserId,
      members: [demoUserId, 'demo-neighbor-2', 'demo-neighbor-3'],
      northMeters: 760,
      hours: 12,
      place: '시연 도서관 앞 벤치',
    ),
    item(
      id: 'demo-joined-open',
      product: '설향 딸기 2팩 함께 사요',
      quantity: '500g × 2팩',
      price: 12000,
      estimate: 4000,
      target: 3,
      owner: 'demo-owner-2',
      members: ['demo-owner-2', demoUserId],
      northMeters: 850,
      hours: 16,
      place: '시연 기숙사 입구',
      strawberries: true,
    ),
    item(
      id: 'demo-matched',
      product: '주말 아침 달걀 같이 나눠요',
      quantity: '30구 · 1인 약 10구',
      price: 10800,
      estimate: 3600,
      target: 3,
      owner: 'demo-owner-3',
      members: ['demo-owner-3', demoUserId, 'demo-neighbor-4'],
      northMeters: 1200,
      hours: 24,
      place: '시연 정문 오른쪽 벤치',
      status: 'matched',
    ),
    item(
      id: 'demo-owned-matched',
      product: '달걀 60구 공동구매',
      quantity: '30구 × 2판',
      price: 18000,
      estimate: 6000,
      target: 3,
      owner: demoUserId,
      members: [demoUserId, 'demo-neighbor-5', 'demo-neighbor-6'],
      northMeters: 1500,
      hours: 30,
      place: '시연 중앙광장',
      status: 'matched',
    ),
    item(
      id: 'demo-cancelled',
      product: '마감된 딸기 나눔 모집',
      quantity: '500g × 3팩',
      price: 15000,
      estimate: 5000,
      target: 3,
      owner: 'demo-owner-4',
      members: ['demo-owner-4', demoUserId],
      northMeters: 1750,
      hours: -2,
      place: '시연 후문 편의점 앞',
      status: 'cancelled',
      strawberries: true,
    ),
    item(
      id: 'demo-owned-cancelled',
      product: '딸기 4팩 같이 주문해요',
      quantity: '500g × 4팩',
      price: 24000,
      estimate: 6000,
      target: 4,
      owner: demoUserId,
      members: [demoUserId, 'demo-neighbor-7'],
      northMeters: 1900,
      hours: -6,
      place: '시연 체육관 입구',
      status: 'cancelled',
      strawberries: true,
    ),
  ];
  return {for (final value in items) value['id'] as String: value};
}

Map<String, Map<String, ChatMessage>> demoMessages(DateTime now) {
  ChatMessage message(String uid, String text, int minutesAgo) =>
      ChatMessage(uid, text, now.subtract(Duration(minutes: minutesAgo)));
  return {
    'demo-matched': {
      'seed-1': message(
        'demo-owner-3',
        '인원이 모두 모였네요! 오늘 저녁 7시에 정문 앞에서 만날까요?',
        38,
      ),
      'seed-2': message('demo-neighbor-4', '좋아요. 달걀 담을 작은 봉투 챙겨갈게요.', 32),
      'seed-3': message(demoUserId, '저도 괜찮아요! 도착하면 여기로 연락할게요.', 25),
      'seed-4': message('demo-owner-3', '네, 정문 오른쪽 벤치에서 만나요.', 5),
    },
    'demo-owned-matched': {
      'seed-1': message(
        demoUserId,
        '함께할 이웃이 모두 모였어요! 오늘 오후 6시에 중앙광장에서 나눠요.',
        20,
      ),
      'seed-2': message('demo-neighbor-5', '감사합니다. 5분 전에 도착해서 연락드릴게요.', 14),
      'seed-3': message('demo-neighbor-6', '저도 시간 맞춰 갈게요!', 8),
    },
  };
}
