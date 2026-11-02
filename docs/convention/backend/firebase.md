# Firebase / Node 서버 규칙

- Node 22 CommonJS. domain.js는 Firebase와 분리하여 순수 규칙을 테스트한다.
- Callable은 request.auth를 확인하고 body uid를 신뢰하지 않는다.
- 입력은 서버에서 타입·길이·범위 검증. ID는 경로 구분자를 허용하지 않는다.
- 참여/취소는 트랜잭션 안에서 최신 문서와 서버 시각을 확인한다.
- 트랜잭션 callback에서 푸시·파일 업로드 등 외부 부작용을 수행하지 않는다.
- 만료 상태를 쓰고 예외를 던지면 트랜잭션이 취소되므로 결과를 반환한 뒤 오류 처리한다.
- 등록·메시지는 uid+requestId로 재시도 멱등성을 유지한다.
- 클라이언트 Firestore 권한은 기본 거부. Admin SDK는 rules를 우회하므로 함수가 권한 경계다.
- .env·서비스 계정·비밀번호·토큰을 커밋/로그에 남기지 않는다.
- 운영 상태 변경 알림은 향후 outbox 방식으로 구현하며 매칭 성공과 푸시 성공을 분리한다.
- 검증: npm ci → npm test → npm run check. 통합 변경은 emulator 검증 추가.
