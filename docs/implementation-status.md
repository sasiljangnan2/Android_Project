# 구현 현황

작성일: 2026-11-24 (Asia/Seoul). 작업 경로 `C:\Users\jack4\Android_Project`, 브랜치 `feat/ui-spec-auth`.

## 구현

| 기능 | 현재 상태 | 남은 확인 |
| --- | --- | --- |
| UI 설계서 적용 | 라임/초록·Pretendard·상품 사진·4개 탭·다크 모드·글자 확대 | 실제 사용자 사용성 |
| 로그인·회원가입 | 독립 화면, 입력 검증, 비밀번호 확인, SDK 연결, 로그아웃·재로그인 | 본인 Firebase 앱 연결 후 실제 계정 |
| 시연 계정 | 명시적 로그인, 메모리 계정별 구분·중복 이메일·잘못된 비밀번호 거부, 실행 종료 시 초기화 | 운영 인증으로 사용하지 않음 |
| 주변·내 모집 | 기준점·반경·사진 카드·필터·전체 서비스 지역의 내 모집 | 실제 GPS·권한 |
| 모집 상세·참여 | 참여/취소 확인, 참여자 목록, 별도 매칭 완료, 응답 유실 후 재조회 | Firestore 동시성·마감 경합 |
| 모집 등록 | 제품/조건/장소 3단계, 값 유지·종료 확인, 지도 오류 재시도, 요청 ID 재조회 | 실제 사진·지도·Storage |
| 채팅 | 매칭 참여자 전용 목록/대화, 최근 100개·4초 폴링, 전송 오류·동일 ID 재시도 | 실제 두 계정·권한·네트워크 |
| 앱 내 알림 | 앱에서 확인한 등록·참여 상태, 누르면 최신 상세 조회 | 외부 상태 전환 실시간 수신 |
| 푸시 | 미구현, 준비 상태 안내 | FCM·권한·토큰·이벤트·딥링크 |
| Firebase 준비 | defines 예제·옵션 초기화·에뮬레이터 연결 플래그·연결 가이드 | 실제 프로젝트 생성·연결·배포 |

## 2026-11-24 검증

- `dart format lib test`: 완료.
- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: **10개 통과**. 가입 확인 일치, 가입 후 참여 확인·매칭·채팅 저장·로그아웃/재로그인, 작성 종료 확인·입력 유지, 내 모집의 반경 독립, 참여 응답 유실 재조회, 320×700·글자 200%·다크 모드, 실제 설정 실패 시 시연 대체 차단, 시연 계정·멱등성·상태 규칙, 시스템 뒤로 가기의 상세·탭·회원가입·종료 확인.
- `functions/npm test`: **7개 통과**. 기존 서버 계약·권한·트랜잭션 코드는 이번 변경에서 유지했다.
- `functions/npm run check`: 통과.
- Firebase CLI 15.37.0 Auth 에뮬레이터: 가입·중복 이메일·잘못된 비밀번호·같은 UID 로그인·약한 비밀번호 거부 통과. REST 서비스 통합 검사이며 Flutter의 실제 Firebase 연결 검증은 아니다.
- `flutter build apk --debug --no-pub`: 성공.
- `flutter run -d emulator-5554 --no-pub --no-resident`: 성공. AVD `HungryStudent_API_36_1`의 MainActivity·로그인 화면과 한글/아이콘 렌더링 확인. 수집한 AndroidRuntime/Flutter 오류 로그 없음.
- UI PNG 12개를 생성해 로그인·회원가입·주변·상세·확인 시트·매칭·채팅·마이·작성·내 모집·확대 다크 화면을 확인했다. `output/ui`에 저장하며 Git에는 포함하지 않는다. `native-login.png`는 Android 실행 화면이다.

실제 클라우드 프로젝트·Firestore 동시성·Storage 규칙 통합, Android 실물 기기·iOS·지도/사진 권한, 오프라인 기기 E2E, 성능 수치는 미검증이다. 메모리 시연·Auth 로컬 통합·Android 시연 실행을 각각 구분한다.

## 영상 촬영용 임시 데이터

- 기본 시연 모집을 8건으로 확장했다. 주변 반경 500m/1km/2km에서 각각 1/4/8건을 확인할 수 있다.
- 시연 계정의 내가 연 모집·참여한 모집에 모집 중/매칭 완료/모집 취소를 준비했다. 참여 취소용 모집과 마지막 자리 참여로 매칭되는 모집을 포함한다.
- 매칭된 두 모집에 예시 대화 4개·3개를 넣었다. 새 회원가입 계정에는 기존 개인 모집·채팅을 연결하지 않는다.
- 재실행하면 초기 상태로 돌아가며 마감과 메시지 시각은 실행 시점 기준이다. Firebase 데이터·API·권한 코드는 변경하지 않았다.
- `dart format lib test`, `flutter analyze --no-pub`: 완료, No issues found.
- `flutter test --no-pub --dart-define=CAPTURE_UI=true`: **12개 통과**. 기존 10개에 촬영 데이터 불변식·채팅 권한과 촬영 계정의 내 모집/채팅/답장 흐름을 추가했다.
- Functions 단위 7개 및 구문 검사, 로컬 Auth 에뮬레이터 통합 검사를 다시 실행해 통과했다. Auth 검사는 임시 모집의 Firestore 통합 검사가 아니다.
- 촬영용 위젯 화면 4장을 추가 확인했다. Android 디버그 APK는 `output/android/app-debug.apk`에 갱신했다. 실제 영상 녹화와 이번 데이터 버전의 Android 기기 조작은 수행하지 않았다.
- 촬영 순서는 `docs/demo-video.md`, 데이터 원본은 `lib/features/recruitment/data/demo_data.dart`에 기록했다.

## 다음 단계

본인 Firebase 프로젝트와 실제 대학 정문 좌표를 준비해 `docs/firebase-setup.md`대로 연결한다. 이후 두 계정 동시 참여·마감·Storage·네트워크 장애를 검증하고 FCM을 구현한다. 단일 캠퍼스 전체 조회는 운영 규모에 맞게 지리 인덱스·페이지네이션으로 확장한다.
