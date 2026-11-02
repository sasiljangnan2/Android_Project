# 아키텍처

Flutter 화면 → RecruitmentRepository → FirebaseRepository → Firebase Auth 인증이 첨부된 Callable → Firestore/Storage.
시연 화면은 같은 Repository 인터페이스의 DemoRepository를 사용한다.
화면에서 Firestore 참여자 배열·상태를 직접 수정하지 않는다.

## 결정
- MVP 상태 관리는 StatefulWidget. 복잡한 상태가 생기면 기능별 Controller로 분리한다.
- 읽기까지 Callable로 통일하여 서버에서 마감 상태·인증·거리·채팅 권한을 확인한다.
- Firestore rules는 모든 클라이언트 접근 거부. Admin SDK의 우회 권한은 Callable에서 제한한다.
- 모집 문서 안의 members 배열이 참여 관계와 인원의 단일 진실. 별도 count 불일치 방지.
- 참여·취소는 문서 읽기/검증/수정을 한 트랜잭션으로 수행하여 마지막 자리 경합 시 재검증한다.
- 모집 ID는 uid_requestId, 메시지 ID도 uid_requestId로 만들어 응답 유실 후 같은 요청이 중복 저장되지 않는다.
- 사진은 모집 전에 본인 Storage 경로에 업로드, 서버에서 실존·크기·타입 확인 후 생성한다.
- 마감 배치는 1분 주기. 조회·참여 경로도 서버 시각으로 마감을 확인하므로 지연된 배치에 의존하지 않는다.
- Firebase 로그인 세션은 SDK가 처리한다. 비밀번호를 따로 저장하지 않는다.

## 알려진 한계
단일 캠퍼스용 전체 스캔 목록은 데이터 증가 시 비용·응답시간 문제가 생긴다.
운영 전 geohash 후보 검색, 서버 거리 재검증, 커서 페이지네이션을 도입한다.
전송된 채팅 최근 100개만 조회한다. 폴링은 즉시 푸시가 아니다.
미등록 사진 정리 작업, App Check와 남용 방지, 실제 네트워크 복구 검증은 후속 작업이다.
현재 UI의 사진 다운로드 URL은 SDK에서 조회한다. Storage는 인증 사용자 사진 읽기 허용 정책이며 공개 게시물용이다.
