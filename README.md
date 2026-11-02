# 배고픈 자취생

대학 주변 자취생을 위한 지역 기반 공동구매 모집·매칭 Flutter 앱입니다.
매칭 완료는 **모집 완료**입니다. 실제 구매·결제·분배·수령은 참여자가 직접 협의합니다.

## 빠른 실행

Flutter 3.47.7 / Dart 3.13.5에서 작성했습니다. Android Studio에서 이 폴더 전체를 여세요.
`android/` 폴더만 열지 마세요.

```powershell
flutter pub get
flutter devices
flutter run -d chrome
# 또는 Android 에뮬레이터를 켜고
flutter run -d <device-id>
```

기본 실행은 **시연 모드**입니다. 실제 계정·서버 저장 없이 목록, 거리 선택, 등록, 참여, 매칭, 채팅 흐름을 확인합니다.
샘플 좌표는 대학 정문이 아니며 앱 종료 시 데이터가 사라집니다. 시연 계정은 실제 로그인 계정이 아닙니다.
사진 선택과 지도 타일 조회에는 운영체제 권한과 인터넷이 필요합니다.
목록의 ‘계란 한 판 함께 구매해요’에 참여하면 목표 2명이 되어 채팅 진입을 확인할 수 있습니다.

## Windows 한글 경로의 Android 빌드

요청한 원본 폴더는 그대로 유지합니다. Windows Android 도구는 `일/깃` 같은 한글 경로에서 빌드를 차단할 수 있습니다.
아래 스크립트는 영문 경로에 작업용 사본을 만들어 빌드하고 APK를 원본의 `output/android/`에 복사합니다.
원본이나 기존 Git을 이동·삭제하지 않습니다. 작업 사본은 삭제하지 않고 경로를 출력합니다.

```powershell
.\tools\build-android.ps1
```

Android SDK Command-line Tools는 Android Studio SDK Manager에서 설치하고,
`flutter doctor --android-licenses`로 라이선스를 직접 검토하세요.
기본 스크립트는 시연 APK입니다. 실제 모드는 `-FlutterArguments`에 dart-define 인자를 넘기세요.
Android Studio에서 실행할 때도 출력된 영문 경로의 사본을 열 수 있습니다.
원본 수정 후에는 스크립트를 다시 실행해 새 사본에 반영하세요.

## 실제 Firebase 연결

[연결 안내](docs/firebase-setup.md)에 따라 본인 Firebase 프로젝트를 설정하세요.
Firebase Auth 이메일·비밀번호, Storage, Firestore와 서울 리전 Callable Functions를 사용합니다.
실제 모드 설정 오류를 시연 데이터로 자동 대체하지 않습니다.

```powershell
flutter run --dart-define=USE_FIREBASE=true --dart-define=GATE_LAT=<검증한위도> --dart-define=GATE_LNG=<검증한경도> --dart-define=GATE_NAME=대학정문
```

## 구성

| 경로 | 내용 |
| --- | --- |
| `lib/core/` | 앱 설정, 거리·금액·시각 표시 |
| `lib/features/recruitment/domain/` | 모집·채팅 모델 |
| `lib/features/recruitment/data/` | 공통 저장소 인터페이스, 시연·Firebase 구현 |
| `lib/features/recruitment/presentation/` | 로그인, 목록, 상세, 등록, 지도, 채팅 |
| `functions/` | 서버 검증, 원자적 참여·취소, 중복 요청 방지, 마감 처리 |
| `docs/` | 요구사항, 화면·API·ERD, 테스트 계획, 개발 규칙 |
| `AGENTS.md` | 이후 개발 도구가 따라야 하는 프로젝트 규칙 |

## 구현 범위와 제한

- FR-01: 500m·1km·2km 탐색, 서비스 반경 2km 중복 필터, 5초 위치 실패 시 정문 전환, 상세.
- FR-02: 사진·제품·수량·가격·직접 입력 예상 비용·인원·마감·지도 수령 장소 등록. 모집자를 첫 참여자로 저장.
- FR-03: Firestore 트랜잭션으로 중복 참여·정원 초과 차단, 모집 중 참여 취소, 정원 충족 시 매칭.
- FR-04: 매칭된 참여자 전용 채팅. 최근 100개를 4초 간격으로 조회하는 초기 구현.
- FR-05: 푸시 알림 **미구현**. 상태는 서버 재조회로 확인. 알림 확장 계약은 명세에 기록.
- 마감은 1분 주기 스케줄러 및 조회·참여 경로에서 서버 시각으로 검증.
- 사진 실패·통신 실패·빈 결과를 구분. 미확인 참여 결과는 새로고침 전 재전송 차단.
- 지도는 flutter_map + OpenStreetMap 타일. 실제 학교 좌표와 운영용 지도 제공자 확정 필요.
- 단일 캠퍼스 초기 버전: 서버 목록은 전체 모집 조회 후 거리 필터링. 대규모 운영 전 지리 인덱스·페이지네이션 필요.
- 내 참여 탭도 현재 기준점·반경 안의 모집만 표시. 전체 참여 이력 API는 추후 추가.
- 모집 수정·삭제, 후기·별점, 강제 퇴장, 결제·정산·AI 추천은 포함하지 않음.
- Firebase 리소스 생성·배포·과금 설정 및 실제 기기 E2E 검증은 수행하지 않음.
- iOS는 프로젝트 파일만 생성. 빌드·실행에는 macOS와 Xcode 필요.

## 문서

[문서 목차](docs/README.md) · [요구사항](docs/specification.md) · [화면](docs/screens.md) · [API](docs/api/README.md) · [ERD](docs/erd/README.md) · [테스트](docs/testing.md) · [작업 현황](docs/implementation-status.md)

참고: [Backpack_Crop](https://github.com/sasiljangnan2/Backpack_Crop)의 docs/api·erd·convention 분류 방식을 참고했습니다.
다른 앱의 도메인이나 Spring 서버는 복제하지 않았습니다.
기존 README는 `docs/reference/original-readme.md`에 보존했습니다.
