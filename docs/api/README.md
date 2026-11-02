# Callable API 명세 v0.1

리전 `asia-northeast3`, 모든 함수 Firebase Auth 필수. uid는 서버 request.auth에서만 가져온다.
HTTPS Callable 프로토콜과 SDK를 사용한다. 임의 REST 경로를 만들지 않는다.
키 camelCase, 금액 정수 원, 거리 m, deadline/at UTC ISO-8601, lat/lng 십진 도.

## 모집 응답
`{id, product, quantity, price, estimate, target, ownerId, members: string[], deadline, place, lat, lng, photo, status, createdAt?}`
status: `open | matched | cancelled`. 인원은 members.length. photo는 Storage 경로.

| 함수 | 요청 | 응답 | 주요 검증 |
| --- | --- | --- | --- |
| listRecruitments | `{lat, lng, radius: 500|1000|2000}` | 모집 배열 | 인증·좌표·서비스 반경 AND 검색 반경, 거리순 |
| getRecruitment | `{id}` | 모집 | 인증·존재·마감 갱신 |
| createRecruitment | `{requestId, product, quantity, price, estimate, target, deadline, place, lat, lng, photo}` | 모집 | 사진 실존·소유 경로, 필수값·금액·인원·미래 마감·정문 반경 |
| joinRecruitment | `{id}` | 모집 | 트랜잭션으로 마감·모집 상태·정원·중복 재검증 |
| cancelParticipation | `{id}` | 모집 | 모집 중, 모집자 불가, 본인만 제거 |
| listMessages | `{id}` | `[{uid,text,at}]` | 매칭 참여자만, 최근 100개 시간순 |
| sendMessage | `{id,requestId,text}` | `{ok:true}` | 매칭 참여자만, 1~1000자, 동일 요청 ID 중복 없음 |

requestId/id는 영문·숫자·하이픈·밑줄 1~100자. 모집 생성 ID: uid_requestId.
동일 requestId의 재호출은 최초 결과를 반환한다. 내용을 바꿀 때는 새 요청으로 처리해야 한다.
응답 유실 시 생성은 같은 requestId, 참여는 getRecruitment 재조회 후 필요할 때만 수동 재시도한다.
회원가입/로그인/로그아웃은 Firebase Auth SDK. 사진 업로드는 Storage SDK.

## 오류
`unauthenticated`: 로그인 필요. `invalid-argument`: 필수값·형식 오류.
`not-found`: 유효하지 않은 모집. `permission-denied`: 채팅 권한 없음.
`failed-precondition`: 정원·상태·마감·지도 설정·사진 검증 실패.
`internal` 또는 시간 초과: 성공 단정 금지, 최신 상태 확인 후 수동 재시도.
Callable SDK의 code/message를 이용하고 예외 전체·인증값은 사용자 화면/로그에 노출하지 않는다.

## FR-05 후속 계약 (미구현)
기기별 FCM 토큰은 본인만 등록/삭제. 서버 상태 전환 이벤트로 outbox 작성.
이벤트 ID는 모집 ID+상태 버전으로 중복 방지. 전송 실패 재시도와 무효 토큰 정리.
알림 payload에는 모집 ID만 담고 앱에서 getRecruitment를 호출한다.
푸시 실패는 참여·매칭 트랜잭션을 되돌리지 않는다.
