# backend

서버 스택은 아직 정하지 않았어요. 후보:

| 선택지 | 장점 | 비고 |
| --- | --- | --- |
| Firebase (Auth + Firestore + Functions) | 서버 관리 없음, Flutter 연동 쉬움 | 혼자/소규모 팀에 빠름 |
| Supabase (Postgres + Auth) | SQL, 무료 티어 넉넉 | Flutter SDK 있음 |
| Spring Boot / NestJS / FastAPI + DB | 수업·포트폴리오용으로 구조를 보여주기 좋음 | 배포 직접 해야 함 |

## API 초안 (스택과 무관)

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| POST | /auth/signup, /auth/login | 회원가입 · 로그인 |
| GET | /me | 골드 · 성실볼 · 탐색 남은 횟수 · 연속 출석 |
| GET/POST/PATCH/DELETE | /habits | 습관 CRUD (카테고리, 측정 방식, 목표량, 기간) |
| POST | /checkins | 오늘 습관 기록 → 성실도·골드·카테고리 레벨 계산 결과 반환 |
| POST | /explore | 탐색 1회 → 몬스터 등장 (아직 안 잡음) / 아무도 없음 |
| POST | /explore/throw | 나타난 몬스터에게 성실볼 1개 → 잡음(새 몬스터) / 잡음(중복 +15G) / 놓침(도망) |
| GET | /monsters | 내 몬스터 목록 (레벨 · EXP · 호감도 · 필드/가방) |
| POST | /monsters/{id}/pet, /play | 하루 1회 교감 → 호감도 |
| POST | /monsters/{id}/feed | 물약 사용 → EXP · 레벨업 · 진화 |
| PATCH | /monsters/{id} | 필드 ↔ 가방 이동 (필드 최대 5) |
| POST | /shop/buy | 물약 · 성실볼 구매 (개수 `count` 포함, 합계 골드는 서버가 계산) |
| GET/POST/PATCH/DELETE | /goals | 주간(3) · 월간(1) 목표, 달성 체크 시 골드 |
| GET | /stats | 최근 7일 성실도, 카테고리별 레벨, 출석 |

## 서버가 꼭 검증해야 하는 것

골드·EXP·호감도는 앱에서 계산해 보내지 말고 서버가 계산해요 (조작 방지).
하루 제한(습관 3개 반영, 탐색 3회, 쓰다듬기·놀아주기 1회)은 서버 날짜 기준으로 초기화해요.
수치는 `docs/economy-v1.md`와 `frontend/lib/core/constants/economy.dart`를 같이 맞춰요.

## 프론트 연동 지점 (지금은 로컬 계산)

서버를 붙일 때 화면 코드는 손대지 않고 아래만 바꾸면 되게 나눠 뒀어요.

| 지금 (Flutter, 로컬) | 바꿀 곳 | 돌려주는 모양 |
| --- | --- | --- |
| `GameState.recordCheckin(habit, value)` | `POST /checkins` 호출 → 응답을 `CheckinResult`로 | `lib/data/results.dart` |
| `GameState.explore()` | `POST /explore` 호출 → `EncounterResult` | 〃 |
| `GameState.throwBall(species)` | `POST /explore/throw` 호출 → `CatchResult` | 〃 |
| `GameState.pet / play / feed / buy(item, count:) / toggleGoal / openCategory …` | 각 API 호출 후 응답으로 상태 갱신 | |

- 서버 호출로 바꾸면 이 메서드들은 `Future`가 돼요. 호출하는 곳은 `ChatController`(`lib/features/chat/`)와 각 화면의 버튼 콜백뿐이에요.
- 탐색의 랜덤은 지금 `GameState(random: …)`로 주입해요 (테스트용). 서버에선 서버가 뽑아요.

## AI 챗봇 연결

챗봇은 "무슨 말을 할지"(`ChatBrain`)와 "대화 흐름"(`ChatController`)을 나눠 뒀어요.

- `lib/features/chat/chat_brain.dart`의 `ChatBrain` 인터페이스를 구현한 `AiChatBrain`을 만들고
  `ChatScreen(controllerBuilder: (s) => ChatController(state: s, brain: AiChatBrain(...)))`로 넘기면 돼요.
- 모든 대사 메서드가 `Future<String>`이라 LLM 호출을 그대로 넣을 수 있고, 기다리는 동안 화면에 "…" 말풍선이 뜨고 입력이 잠겨요.
- 보상 계산은 계속 `GameState`(나중엔 서버)가 해요. AI는 말만 하고 숫자는 정하지 않게 두는 게 안전해요.
- 자유 입력("30분 뛰었어")을 받으려면 `ChatController`에 문장 → 값 해석 단계를 추가하면 돼요 (지금은 버튼/숫자 입력).
