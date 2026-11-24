import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungry_student/main.dart';
import 'package:hungry_student/features/recruitment/data/demo_repository.dart';
import 'package:hungry_student/features/recruitment/domain/recruitment.dart';

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('output/ui/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> app(
  WidgetTester tester,
  DemoRepository repository, {
  ThemeMode theme = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('capture'),
      child: HungryStudentApp(repository: repository, themeMode: theme),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final name in ['eggs', 'strawberries']) {
      await precacheImage(AssetImage('assets/images/$name.png'), context);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('가입 검증 → 가입 → 참여 확인 → 매칭 → 채팅 → 로그아웃·재로그인', (tester) async {
    phone(tester);
    final repository = DemoRepository();
    await app(tester, repository);
    expect(repository.uid, isNull);
    await capture(tester, '01-login');
    await tapVisible(tester, find.text('처음 오셨나요? 회원가입'));
    await capture(tester, '02-signup');
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'neighbor@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'Pass1234!');
    await tester.enterText(find.byKey(const Key('auth-confirm')), 'different');
    await tapVisible(tester, find.byKey(const Key('auth-submit')));
    expect(find.text('비밀번호가 일치하지 않아요.'), findsOneWidget);
    expect(repository.uid, isNull);
    await tester.enterText(find.byKey(const Key('auth-confirm')), 'Pass1234!');
    await tapVisible(tester, find.byKey(const Key('auth-submit')));
    expect(repository.uid, isNotNull);
    expect(find.text('주변 모집'), findsOneWidget);
    await capture(tester, '03-nearby');
    await tapVisible(tester, find.text('달걀 30구 같이 나눠요'));
    await capture(tester, '04-detail');
    await tapVisible(tester, find.byKey(const Key('join-recruitment')));
    await capture(tester, '05-join-confirmation');
    expect((await repository.get('demo-0')).members, hasLength(2));
    await tapVisible(tester, find.text('다음에 할게요'));
    expect((await repository.get('demo-0')).members, hasLength(2));
    await tapVisible(tester, find.byKey(const Key('join-recruitment')));
    await tapVisible(tester, find.byKey(const Key('confirm-participation')));
    expect((await repository.get('demo-0')).status, 'matched');
    expect(find.text('매칭 완료'), findsOneWidget);
    await capture(tester, '06-match');
    await tapVisible(tester, find.text('참여자 채팅으로 이동'));
    await tester.enterText(find.byKey(const Key('chat-input')), '오늘 저녁에 만날까요?');
    await tapVisible(tester, find.byKey(const Key('chat-send')));
    expect(find.text('오늘 저녁에 만날까요?'), findsOneWidget);
    expect(await repository.messages('demo-0'), hasLength(1));
    await capture(tester, '07-chat');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('마이'));
    await capture(tester, '08-profile');
    await tapVisible(tester, find.text('로그아웃'));
    expect(repository.uid, isNull);
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'neighbor@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'Pass1234!');
    await tapVisible(tester, find.byKey(const Key('auth-submit')));
    expect(repository.email, 'neighbor@example.com');
    expect(find.text('주변 모집'), findsOneWidget);
  });
  testWidgets('모집 작성 값을 유지하고 나가기 확인 시트를 표시', (tester) async {
    phone(tester);
    final repository = DemoRepository();
    await repository.signIn(
      DemoRepository.demoEmail,
      DemoRepository.demoPassword,
    );
    await app(tester, repository);
    await tapVisible(tester, find.text('모집 만들기'));
    await capture(tester, '09-create-product');
    await tester.enterText(
      find.widgetWithText(TextFormField, '제품명'),
      '함께 나눌 우유',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('작성을 그만둘까요?'), findsOneWidget);
    await tapVisible(tester, find.text('계속 작성하기'));
    expect(find.text('함께 나눌 우유'), findsOneWidget);
    await tester.tap(find.byTooltip('이전 단계'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('작성 그만두기'));
    expect(find.text('주변 모집'), findsOneWidget);
  });
  testWidgets('검색 반경을 바꿔도 내 참여 목록은 서비스 지역 전체에서 조회', (tester) async {
    phone(tester);
    final repository = DemoRepository();
    await repository.signIn(
      DemoRepository.demoEmail,
      DemoRepository.demoPassword,
    );
    await repository.participate('demo-1');
    await app(tester, repository);
    await tapVisible(tester, find.text('500m'));
    expect(find.text('딸기 1kg 함께 나눠요'), findsNothing);
    await tapVisible(tester, find.text('내 모집'));
    await tapVisible(tester, find.text('참여한 모집'));
    expect(find.text('딸기 1kg 함께 나눠요'), findsOneWidget);
    await capture(tester, '10-my-recruitments');
    await tapVisible(tester, find.text('주변 모집'));
    expect(find.text('딸기 1kg 함께 나눠요'), findsNothing);
  });
  testWidgets('참여 응답 유실은 성공으로 표시하지 않고 재조회로 확인', (tester) async {
    phone(tester);
    final repository = LostResponseRepository();
    await repository.signIn(
      DemoRepository.demoEmail,
      DemoRepository.demoPassword,
    );
    await app(tester, repository);
    await tapVisible(tester, find.text('달걀 30구 같이 나눠요'));
    await tapVisible(tester, find.byKey(const Key('join-recruitment')));
    await tapVisible(tester, find.byKey(const Key('confirm-participation')));
    expect(find.text('함께할 이웃이\n모두 모였어요!'), findsNothing);
    await tapVisible(tester, find.text('최신 상태 다시 확인하기'));
    expect(find.text('참여자 채팅 열기'), findsOneWidget);
    expect((await repository.get('demo-0')).members, hasLength(3));
  });
  testWidgets('좁은 화면·글자 200%·다크 모드에서 주요 화면이 넘치지 않음', (tester) async {
    phone(tester, size: const Size(320, 700));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = DemoRepository();
    await app(tester, repository, theme: ThemeMode.dark);
    expect(tester.takeException(), isNull);
    await capture(tester, '11-large-dark-login');
    await repository.signIn(
      DemoRepository.demoEmail,
      DemoRepository.demoPassword,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, '12-large-dark-nearby');
    for (final label in ['내 모집', '채팅', '마이', '주변 모집']) {
      await tapVisible(tester, find.text(label));
      expect(tester.takeException(), isNull);
    }
    await tester.scrollUntilVisible(
      find.text('달걀 30구 같이 나눠요'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, find.text('달걀 30구 같이 나눠요'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('시스템 뒤로 가기는 상세·탭·회원가입 순서와 종료 확인을 처리', (tester) async {
    phone(tester);
    final repository = DemoRepository();
    await app(tester, repository);
    await tapVisible(tester, find.text('처음 오셨나요? 회원가입'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-confirm')), findsNothing);
    await repository.signIn(
      DemoRepository.demoEmail,
      DemoRepository.demoPassword,
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('마이'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('나의 장보기'), findsNothing);
    await tapVisible(tester, find.text('달걀 30구 같이 나눠요'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('모집 상세'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('앱을 종료할까요?'), findsOneWidget);
    await tapVisible(tester, find.text('계속 둘러보기'));
  });
  testWidgets('촬영용 계정으로 내 모집·채팅 예시를 바로 확인하고 답장 전송', (tester) async {
    phone(tester);
    final repository = DemoRepository();
    await app(tester, repository);
    await tapVisible(tester, find.byKey(const Key('demo-login')));
    expect(repository.email, DemoRepository.demoEmail);
    await capture(tester, '13-recording-nearby');
    await tapVisible(tester, find.text('내 모집'));
    expect(find.text('달걀 40구 나눌 이웃 구해요'), findsOneWidget);
    await capture(tester, '14-recording-owned');
    await tapVisible(tester, find.text('채팅'));
    await capture(tester, '15-recording-chats');
    await tapVisible(tester, find.text('주말 아침 달걀 같이 나눠요'));
    expect(find.text('네, 정문 오른쪽 벤치에서 만나요.'), findsOneWidget);
    await capture(tester, '16-recording-conversation');
    final before = (await repository.messages('demo-matched')).length;
    await tester.enterText(find.byKey(const Key('chat-input')), '네! 7시에 뵐게요.');
    await tapVisible(tester, find.byKey(const Key('chat-send')));
    expect(await repository.messages('demo-matched'), hasLength(before + 1));
    expect(find.text('네! 7시에 뵐게요.'), findsOneWidget);
  });
  testWidgets('실제 설정 오류는 시연 화면으로 대체하지 않음', (tester) async {
    await tester.pumpWidget(
      const HungryStudentApp(repository: null, startupError: '설정 확인 필요'),
    );
    expect(find.text('설정 확인 필요'), findsOneWidget);
    expect(find.textContaining('시연 모드'), findsNothing);
  });
}

class LostResponseRepository extends DemoRepository {
  @override
  Future<Recruitment> participate(String id, {bool cancel = false}) async {
    await super.participate(id, cancel: cancel);
    throw TimeoutException('Response lost');
  }
}
