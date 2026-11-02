import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungry_student/main.dart';
import 'package:hungry_student/features/recruitment/data/demo_repository.dart';

void main() {
  testWidgets('시연 목록에서 상세 조회 및 참여', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(HungryStudentApp(repository: DemoRepository()));
    await tester.pumpAndSettle();
    expect(find.textContaining('시연 모드'), findsOneWidget);
    await tester.tap(find.text('계란 한 판 함께 구매해요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('함께 구매할 사람으로 참여하기'));
    await tester.pumpAndSettle();
    expect(find.text('매칭 완료'), findsOneWidget);
    expect(find.text('참여자 채팅'), findsOneWidget);
    expect(find.text('참여 취소'), findsNothing);
  });
  testWidgets('실제 설정 오류는 시연 화면으로 대체하지 않음', (tester) async {
    await tester.pumpWidget(
      HungryStudentApp(repository: DemoRepository(), startupError: '설정 확인 필요'),
    );
    expect(find.text('설정 확인 필요'), findsOneWidget);
    expect(find.textContaining('시연 모드'), findsNothing);
  });
}
