# 배고픈 자취생

대학 주변 이웃과 함께 구매할 사람을 찾는 Flutter 앱입니다. 매칭 완료는 모집 인원이 모였다는 뜻이며 구매·결제 완료를 의미하지 않습니다.

## 실행

Android Studio에서 **`C:\Users\jack4\Android_Project` 폴더 전체**를 엽니다. `android/`만 열지 않습니다. 이 PC에는 Flutter와 프로젝트용 AVD `HungryStudent_API_36_1`가 준비되어 있습니다. Flutter 3.47.7 / Dart 3.13.5 기준입니다.

```powershell
flutter pub get
flutter run -d <Android-device-id>
# 웹으로 확인
flutter run -d chrome
```

## 로그인과 회원가입

추가 Firebase 설정 없이 기본 시연 모드로 실행됩니다. 첫 로그인 화면의 **처음 오셨나요? 회원가입**에서 이메일·6자 이상 비밀번호·비밀번호 확인을 입력하세요. 가입하면 주변 모집으로 이동합니다. 마이에서 로그아웃한 후 같은 계정으로 재로그인할 수 있습니다. 중복 이메일과 잘못된 비밀번호도 구분합니다.

시연 계정·모집은 메모리에만 저장되어 앱 프로세스를 종료하면 사라집니다. 실제 Firebase 계정은 생성되지 않습니다. **시연 계정으로 둘러보기**로 바로 확인할 수도 있습니다. ‘달걀 30구 같이 나눠요’는 2/3명으로 시작하므로 참여 확인 → 매칭 완료 → 참여자 채팅 흐름을 볼 수 있습니다. 정문·모집 좌표는 실제 대학이 아닌 샘플입니다.

영상 촬영용 모집 8건과 예시 대화 7개를 포함합니다. 시연 계정에는 내가 연 모집·참여한 모집의 모집 중/매칭 완료/취소 상태가 준비되어 있습니다. [촬영 순서와 데이터 안내](docs/demo-video.md)를 확인하세요. 반영하려면 Hot Restart 또는 앱을 완전히 재실행합니다.

## 화면

[2026-11-02 UI 설계서](https://docs.google.com/presentation/d/1mNupTDLWZvoqUiunBwKmcmP0TeLJAkwTENfhS2Z127Q)에 따라 라임 버튼, 진한 초록 본문, 아이보리 배경, Pretendard를 적용했습니다.

- 주변 모집: 현재 위치/정문, 500m·1km·2km, 사진·비용·인원·마감·직선거리 카드.
- 내 모집: 내가 연 모집/참여한 모집, 상태 필터. 선택한 검색 반경과 별도로 정문 2km 서비스 지역 전체를 확인합니다.
- 채팅: 매칭된 참여자의 대화와 참여자 목록. 최근 100개를 4초마다 조회합니다.
- 마이: 계정, 위치 기준, 앱 내 상태 알림, 로그아웃.
- 모집 만들기: 제품 → 조건 → 장소 3단계, 이전 단계 값 유지, 종료 확인, 성공 후 내가 연 모집 이동.
- 상세: 사진, 전체 가격·참고 예상 비용, 참여/취소 확인 시트, 별도 매칭 완료 화면.

시스템 다크 모드와 글자 크기를 따릅니다. 사진 선택에는 운영체제 권한이, 지도 타일에는 인터넷이 필요합니다. 위치 취득 실패 시 정문 기준으로 전환합니다.

## Firebase 연결 준비

Auth 이메일 회원가입·로그인·로그아웃 SDK와 Storage/Callable 서버 코드가 준비되어 있습니다. **본인 Firebase 프로젝트는 아직 연결하지 않았습니다.**

1. [연결 안내](docs/firebase-setup.md)에 따라 본인 Firebase 앱과 이메일/비밀번호 인증을 준비합니다.
2. `config/firebase.example.json`을 `config/firebase.local.json`으로 복사하고 앱 설정과 검증한 실제 정문 좌표를 채웁니다.
3. Functions와 보안 규칙을 본인 프로젝트에 배포한 후 실행합니다.

```powershell
flutter run --dart-define-from-file=config/firebase.local.json
```

설정 오류는 안내 화면으로 멈추며 실제 요청 실패를 시연 성공으로 바꾸지 않습니다. 클라우드 리소스 생성·배포는 수행하지 않았습니다.

## 검증

```powershell
dart format lib test
flutter analyze
flutter test
cd functions
npm test
npm run check
cd ..
npx firebase-tools emulators:exec --only auth --project demo-hungry-student "node tools/test-auth-emulator.mjs"
```

`flutter test --dart-define=CAPTURE_UI=true`로 `output/ui/`에 화면 PNG를 생성할 수 있습니다. 결과·검증 범위는 [구현 현황](docs/implementation-status.md)을 확인하세요.

## 남은 범위

FCM 푸시는 미구현입니다. 앱에서 확인한 상태 알림만 표시하며 토큰 수집·알림 권한 요청은 없습니다. 실제 Firebase 두 계정 동시 참여·마감 경합, Storage·지도 권한, 실제 기기·iOS·성능 검증이 남아 있습니다. 모집 수정·삭제, 후기, 강제 퇴장, 결제·정산은 포함하지 않습니다. 단일 캠퍼스 초기 버전이므로 대규모 운영 전 지리 인덱스·페이지네이션이 필요합니다.

## 구조와 문서

`lib/core`는 설정·테마·오류, `lib/features/auth/presentation`은 계정 화면, `lib/features/recruitment/{domain,data,presentation}`은 모집·채팅, `functions`는 서버 검증·원자적 참여·취소를 담당합니다.

[요구사항](docs/specification.md) · [화면](docs/screens.md) · [API](docs/api/README.md) · [테스트](docs/testing.md) · [작업 현황](docs/implementation-status.md) · [이미지·글꼴과 생성 프롬프트](docs/assets.md)

문서 분류는 [Backpack_Crop](https://github.com/sasiljangnan2/Backpack_Crop)를 참고했습니다. 기존 README는 `docs/reference/original-readme.md`에 보존했습니다. 현재 영문 프로젝트 경로에서 직접 빌드할 수 있으며 한글 경로용 `tools/build-android.ps1`도 보존합니다.
