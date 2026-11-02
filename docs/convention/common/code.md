# 프론트·서버 공통 약속

| 항목 | 약속 |
| --- | --- |
| JSON 키 | camelCase |
| ID | 불투명 문자열, 숫자로 변환하지 않음 |
| 금액 | 정수 원, estimate는 직접 입력 참고 금액 |
| 거리 | 미터, Haversine 직선거리, 경계 포함 ≤ |
| 좌표 | lat/lng, 십진 도 |
| 시각 | UTC ISO-8601, 표시는 기기 로컬 시각 |
| 상태 | open / matched / cancelled |
| 인원 | members 배열 길이, 모집자 포함 |
| 오류 | Callable code/message, 원본 예외 노출 금지 |
| 재시도 | 생성·채팅 requestId 유지, 참여 결과 먼저 조회 |

API 변경은 docs/api와 양쪽 모델·테스트를 같은 작업에서 수정한다.
미구현·시연·실제 저장·검증 완료를 구분해서 문서에 표시한다.
