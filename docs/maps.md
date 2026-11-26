# 지도 기준점과 제공자

## 한성대학교 시작 위치

2026-11-25에 [한성대학교 공식 캠퍼스맵](https://www.hansung.ac.kr/campusMap/hansung/view.do)의 정문(안내실) 항목을 확인했다. 공개 지도 목록 요청 `POST https://www.hansung.ac.kr/campusMap/hansung/buildList.do?srchCampsFilter=`의 building ID 4에 위도 `37.58323278825486`, 경도 `127.01038751364028`이 제공된다.

`AppConfig.demoGate`는 이 위치이며 기본 이름은 한성대학교 정문이다. 새 모집의 지도 선택 화면, 정문 검색 기준·위치 실패 시 복귀점과 가상 모집 8건이 함께 이동한다. 이미 선택한 수령 장소를 다시 열 때는 기존 선택을 유지한다. 모집·거래·수령 장소 이름은 계속 가상 데이터이며 실제 학교 시설 위치를 뜻하지 않는다.

기본 지도는 기존 flutter_map + OpenStreetMap이다. 지도 공급자를 바꾼 것은 아니다. 반영하려면 Hot Restart 또는 앱을 완전히 재실행한다.

실제 Firebase 모드에서는 `GATE_LAT`/`GATE_LNG`를 여전히 명시해야 한다. 본인 프로젝트의 앱 설정과 Functions 환경변수에 같은 정문 좌표를 입력한다. 기본값 변경만으로 운영 서버나 클라우드 설정을 생성·배포하지 않는다.

## 다른 지도

| 선택지 | 앱 적용 시 고려할 점 |
| --- | --- |
| OpenStreetMap + flutter_map (현재) | 현재 코드와 연동됨. 기존 타일 서버는 앱 키 없이 사용하되 출처 표기와 타일 이용 정책을 지킨다. |
| 네이버 지도 | 국내 지도 서비스 대안. 네이버 클라우드 앱 등록·클라이언트 ID와 Flutter 연동 구성이 필요하다. |
| 카카오맵 | 국내 지도와 로컬 장소·주소 검색을 연결할 수 있다. Kakao 앱 등록·키와 Flutter 연동 구성이 필요하다. |
| Google Maps | 공식 Flutter 패키지로 Android/iOS/Web을 지원한다. Google Cloud 프로젝트·API 키·결제 계정 설정이 필요하다. |

국내 대학 주변의 익숙한 지도를 원하면 네이버·카카오를 먼저 검토할 수 있다. 공급자 선택 후 지원 플랫폼·키 제한·쿼터·요금은 해당 콘솔의 현재 조건으로 확인한다.

공식 문서: [네이버 SDK 시작하기](https://navermaps.github.io/android-map-sdk/guide-ko/1.html), [Kakao Maps API](https://apis.map.kakao.com/), [카카오 로컬 API](https://developers.kakao.com/docs/ko/kakaomap/common), [Google Maps for Flutter](https://developers.google.com/maps/flutter-package/overview), [OSM 타일 정책](https://operations.osmfoundation.org/policies/tiles/).
