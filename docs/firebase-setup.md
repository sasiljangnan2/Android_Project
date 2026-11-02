# Firebase 실제 연결

## 1. 준비
본인 Firebase 프로젝트 ID, Android applicationId `com.hungrystudent.hungry_student`, 실제 대학 정문 위도·경도가 필요하다.
Cloud Functions/스케줄러/Storage 사용에 필요한 현재 요금제·과금은 Firebase 콘솔에서 확인한다.
이 프로젝트는 클라우드 리소스를 생성하거나 배포하지 않았다.

## 2. 앱 등록
Firebase 콘솔에서 Android 앱을 등록하고 Authentication 이메일/비밀번호 로그인을 활성화한다.
Firestore와 Storage를 생성한다. 초기 테스트 모드의 공개 규칙을 그대로 사용하지 말고 저장소 rules를 배포한다.
설정 파일·서비스 계정 키를 Git에 올리지 않는다.

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=<본인-project-id> --platforms=android,ios,web
```

Android의 google-services.json은 android/app/에 있어야 한다.
현재 main.dart는 Android/iOS 네이티브 기본 초기화를 사용한다.
**웹 실제 연결 시** 생성한 firebase_options.dart를 import하고 초기화를 아래로 바꾼다.

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

실제 모바일에서도 위 초기화 형태로 통일해도 된다. 생성 파일의 값은 본인 프로젝트의 것만 사용한다.
설정 전 기본 시연 모드는 firebase_options.dart 없이 컴파일된다.

## 3. 서버 설정
functions/.env.example을 functions/.env.<project-id>로 복사하고 검증한 정문 좌표를 입력한다.
앱의 GATE_LAT/GATE_LNG와 반드시 동일하게 설정한다. 설정 누락 시 서버 등록·거리 검색을 차단한다.

```powershell
cd functions
npm ci
npm test
npm run check
cd ..
firebase use --add
# 프로젝트를 확인한 뒤 본인이 배포할 때 실행
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
flutter run --dart-define=USE_FIREBASE=true --dart-define=GATE_LAT=<실제위도> --dart-define=GATE_LNG=<실제경도>
```

실제 프로젝트 별칭 .firebaserc는 사용자 설정으로 생성한다. 예시 ID로 배포하지 않는다.

## 4. 에뮬레이터 통합 검증
Java 21+, Node 22 및 Firebase CLI를 준비한다.

```powershell
firebase emulators:start --project demo-hungry-student
```

앱을 에뮬레이터에 연결하려면 Firebase 초기화 직후 아래 SDK 연결을 추가한다.
Android 에뮬레이터의 host는 10.0.2.2, 웹/PC는 127.0.0.1.

```dart
await FirebaseAuth.instance.useAuthEmulator(host, 9099);
FirebaseFunctions.instanceFor(region: 'asia-northeast3').useFunctionsEmulator(host, 5001);
await FirebaseStorage.instance.useStorageEmulator(host, 9199);
```

현재 코드는 SDK emulator 자동 전환을 제공하지 않는다. 시연 모드와 emulator 모드는 다른 개념이다.
동시 참여·비로그인·채팅 권한은 docs/testing.md 기준으로 검증한다.
일정 함수는 에뮬레이터에서 수동 호출하고 실제 스케줄러는 배포 후 별도로 확인한다.

## 운영 전
실제 학교 좌표 확인, 지도 타일 제공자 확정, 두 계정 동시 참여/마감 경합,
권한 거부/통신 차단/응답 유실, 사진 및 Storage 접근 규칙, 비용·성능을 확인한다.
푸시는 구현 전이며 알림을 위한 토큰 수집이나 권한 요청은 아직 하지 않는다.

공식 근거: [Flutter 설정](https://firebase.google.com/docs/flutter/setup),
[Callable](https://firebase.google.com/docs/functions/callable),
[트랜잭션](https://firebase.google.com/docs/firestore/manage-data/transactions),
[flutter_map](https://docs.fleaflet.dev/).
