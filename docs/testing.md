# 검증 계획

## 자동 검증
flutter analyze, flutter test, functions의 npm test/node --check.
도메인 단위 테스트는 규칙 검증이며 실제 Firestore 동시성 증명이 아니다.

| TC | 관련 요구사항 | 검증 |
| --- | --- | --- |
| TC-01 | FR-01 | 반경 경계 안/밖, 서비스와 검색 반경 교집합, 위치 거부·5초 실패 정문 전환 |
| TC-02 | FR-02 | 정상 등록·사진 실패·필수 누락·목표 1명·과거 마감·지역 밖·동일 요청 재시도 |
| TC-03 | FR-03/NFR-03 | 마지막 한 자리 두 계정 동시 신청, 동일 요청 3회, 취소·마감 경합 |
| TC-04 | FR-04 | 매칭 전·비참여자의 메시지 조회/전송 거부, 매칭된 참여자 허용 |
| TC-05 | FR-05 | 푸시 미구현으로 보류 |
| TC-06 | NFR-01 | 동일 기기·네트워크·데이터에서 각 화면 20회, 목표 19회 이상 |
| TC-07 | NFR-02 | 오프라인 5초 안내, 추가 전송 0건, 응답 유실 후 서버와 일치 |
| TC-09 | NFR-04 | 비로그인 요청 거부·채팅 인가·HTTPS·로그 비밀정보 노출 0건 |

## 에뮬레이터·실제 서비스 필수 확인
1. Auth 두 계정 A/B를 생성하고 모집자 C가 target=2인 모집 생성.
2. A/B로 joinRecruitment를 동시에 호출. 성공 1건, members 길이 2, status matched 확인.
3. 성공 계정으로 동일 신청 3회. 중복·초과 0건 확인.
4. 매칭 후 cancelParticipation 거부 확인.
5. open 모집에서 모집자 취소 거부, 일반 참여자 취소 및 반복 취소 확인.
6. deadline 경계 전후·스케줄러 호출·참여 경쟁에서 최종 상태 및 정원 확인.
7. 인증 없는 모든 callable 거부, Firestore 직접 read/write 거부.
8. 비참여자의 listMessages/sendMessage 거부. 본인 아닌 Storage 경로 업로드 거부.
9. create/send 응답 유실 후 같은 requestId 재전송 시 문서·메시지 1건 확인.
10. 기기 네트워크 차단 후 최신 상태 확인 전 추가 참여 불가 확인.

실제 클라우드, Android/iOS 기기, 권한 대화상자, 네트워크 장애와 성능 검증은 별도 수행한다.
실행 결과는 implementation-status에 기록한다.
