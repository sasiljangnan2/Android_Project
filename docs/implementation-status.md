# 구현 현황

작성일: 2026-11-02 (Asia/Seoul).

| 기능 | 상태 | 남은 검증 |
| --- | --- | --- |
| Flutter Android/iOS/Web 프로젝트 | 생성 | iOS는 Mac에서 확인 |
| 시연 목록·상세·반경·참여·매칭 | 구현 | 수동 기기 흐름 |
| 로그인·회원가입 | Firebase SDK 연결 코드 | 본인 Firebase 설정 후 실제 계정 확인 |
| 모집 등록·사진·지도 | 구현 | 실제 Storage·지도·권한 확인 |
| 원자적 참여·취소·마감 | Functions 구현 | Firestore 동시성·스케줄러 통합 확인 |
| 매칭 후 채팅 | 구현, 최근 100개·4초 폴링 | 실제 두 계정 통합 확인 |
| 푸시 알림 | 후속 구현 | 토큰·이벤트·중복·권한·딥링크 |
| 명세·API·ERD·규칙 | 작성 | 기능 변경 시 동기화 |

## 검증 기록
- `dart analyze`: No issues found. `flutter analyze`는 이 PC의 한글 경로 LSP JSON 파싱 오류로 실패하여 대체 검사 사용.
- `flutter test`: 휴대폰 크기(390×844)에서 2개 통과 (시연 목록→상세→참여→매칭, 실제 설정 실패 시 시연 대체 금지).
- `functions/npm test`: 7개 통과 (거리·설정·등록 검증·멱등성·취소·마감·채팅 인가 규칙).
- `npm run check` 및 Functions 모듈 로드: 통과.
- `flutter build web`: 성공.
- Android 디버그 APK: 영문 작업 사본에서 빌드 성공. output/android/app-debug.apk에 저장. 원본 한글 경로는 Windows 도구가 차단하므로 tools/build-android.ps1을 사용.
- Firebase 실제 연결·Firestore 동시성 통합·iOS 빌드·기기 실행·성능 수치는 미검증.
- 로컬 Node 24.14.0에서 서버 단위 검사 수행, 배포 runtime 및 CI는 Node 22.
- npm audit: 상위 Firebase 패키지를 최신화해도 전이 의존성 glob/minimatch 관련 moderate 6건이 남음. npm audit fix로 해소되지 않음. 무리한 major override는 적용하지 않았으며 운영 전 업데이트 재확인 필요.

## 다음 작업
1. 학교명·정문 좌표 확인, 본인 Firebase 앱 등록·연결.
2. 에뮬레이터에서 권한·동시성·마감·응답 유실 통합 테스트.
3. Android 실제 기기 실행, TC-06 성능 측정, 좁은 화면·큰 글꼴 확인.
4. FR-05 FCM 알림과 딥링크, 실시간 채팅/페이지네이션.
5. 운영 지도 제공자·남용 방지·미사용 사진 정리·탈퇴 데이터 정책.
