# Firebase 실제 연결 준비

기본 실행은 메모리 시연이다. 실제 프로젝트 생성·앱 등록·배포는 수행하지 않았다. 회원가입/로그인/로그아웃은 Firebase Auth SDK 코드까지 준비되어 있다.

## 본인 프로젝트

Firebase 콘솔에서 프로젝트와 Android 앱(applicationId `com.hungrystudent.hungry_student`)을 등록한다. Authentication의 **이메일/비밀번호**를 활성화하고 Firestore·Storage를 준비한다. 필요한 요금제·비용은 본인 콘솔에서 확인하며 서비스 계정 키를 앱/Git에 넣지 않는다.

`config/firebase.example.json`을 `config/firebase.local.json`으로 복사한다. 로컬 파일은 Git에서 제외한다.

| 설정 | 값 |
| --- | --- |
| USE_FIREBASE | true |
| FIREBASE_API_KEY | 앱의 apiKey |
| FIREBASE_APP_ID | 해당 플랫폼 앱의 appId |
| FIREBASE_MESSAGING_SENDER_ID | messagingSenderId |
| FIREBASE_PROJECT_ID | 본인 프로젝트 ID |
| FIREBASE_STORAGE_BUCKET | 콘솔의 storageBucket 그대로 |
| FIREBASE_AUTH_DOMAIN | 웹 앱 authDomain, 모바일은 빈 문자열 가능 |
| GATE_LAT/GATE_LNG/GATE_NAME | 검증한 실제 대학 정문 좌표와 이름 |

앱 값은 Firebase 콘솔 또는 `flutterfire configure`의 FirebaseOptions에서 확인한다. Android/웹의 APP_ID는 각각 해당 앱 값을 사용한다. 예제에 가짜 운영 좌표·프로젝트를 넣지 않는다.

```powershell
flutter run --dart-define-from-file=config/firebase.local.json
```

`lib/core/firebase_bootstrap.dart`에서 defines의 FirebaseOptions로 초기화하므로 소스 수정이나 생성 파일 import가 필요 없다. apiKey를 생략하면 네이티브 기본 설정 초기화를 사용한다. 그 경우 FlutterFire CLI로 네이티브 Gradle/설정 파일을 구성해야 한다. 시연 모드에는 Firebase 파일이 필요 없다.

## 서버

functions/.env.example을 functions/.env.<본인-project-id>로 복사하고 앱과 동일한 검증된 정문 좌표를 입력한다. 공개 테스트 규칙을 사용하지 않는다.

```powershell
npx firebase-tools login
npx firebase-tools use --add
cd functions
npm ci
npm test
npm run check
cd ..
# 본인 프로젝트와 비용을 확인한 뒤 배포할 때 실행
npx firebase-tools deploy --only functions,firestore:rules,firestore:indexes,storage
```

설정 누락은 실제 모드를 차단한다. SDK/서버 실패를 시연 데이터로 대체하지 않으며 Firestore 영구 캐시를 사용하지 않는다.

## 로컬 Auth 통합 검사

실제 키·클라우드 계정 없이 로컬에만 테스트 계정을 생성한다. 토큰·비밀번호를 출력하지 않는다.

```powershell
npx firebase-tools emulators:exec --only auth --project demo-hungry-student "node tools/test-auth-emulator.mjs"
```

2026-11-24 CLI 15.37.0에서 가입, 중복 이메일, 잘못된 비밀번호, 같은 UID 재로그인, 짧은 비밀번호 거부를 확인했다. Flutter UI나 Firestore 동시성 검사를 대신하지 않는다.

앱을 전체 에뮬레이터에 연결할 때는 FirebaseOptions·정문 설정에 `USE_FIREBASE_EMULATORS=true`를 추가한다. `FIREBASE_EMULATOR_HOST` 기본값은 Android 에뮬레이터 `10.0.2.2`, 웹/PC `127.0.0.1`이다. Auth 9099, Functions 5001, Storage 9199에 자동 연결한다. 실제 서비스에서는 이 플래그를 사용하지 않는다. 메모리 시연과 Firebase 에뮬레이터는 서로 다르다.

운영 전 두 계정 동시 참여·마감 경합, Storage 접근, 지도·사진 권한, 응답 유실·네트워크 차단, 비용·성능을 추가 확인한다. FCM 토큰 수집·푸시·알림 권한은 미구현이다.

공식 문서: [Flutter 설정](https://firebase.google.com/docs/flutter/setup), [이메일 인증](https://firebase.google.com/docs/auth/flutter/password-auth), [Callable](https://firebase.google.com/docs/functions/callable).
