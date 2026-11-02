# Flutter / Dart 규칙

- Effective Dart와 flutter_lints를 기준으로 dart format 결과를 사용한다.
- 파일·폴더 snake_case, 클래스 UpperCamelCase, 변수·함수·enum lowerCamelCase.
- 가능한 final/const, public API 타입 명시, JSON 경계 이외 dynamic 최소화.
- core에는 공통 설정·형식, features/{domain}/domain·data·presentation에 기능별 코드.
- 화면은 Repository로만 서버에 접근한다. 시연/실제 데이터 공급자를 혼합하지 않는다.
- 비동기 후 mounted 확인, controller/timer dispose, 중복 제출 차단.
- 화면에 토큰·원본 예외·비밀번호 노출 금지. 서버 오류는 사용자가 이해하는 문장으로 변환.
- build에서 네트워크 호출하지 않는다. initState/명시적 사용자 동작에서 조회.
- 금액은 int 원화, 시각은 UTC 전송 후 toLocal 표시.
- 문자열은 한국어. 현 버전은 화면별 문구이며 다국어 도입 시 l10n으로 이동한다.
- 검증: dart format lib test → flutter analyze → flutter test.
