# DB v1.5 (공식 설계) — 앱 · 서버에 맞추기

DB 담당이 보내 준 **schema.sql v1.5** 기준 메모예요 (받은 파일: `habit_monster_erd.md`, `seed.sql`, `verify.sql`, `verify_later.sql` · 2026-10-08 작성본).
원본 파일은 저장소에 넣지 않고 공유 폴더(OneDrive `카카오톡 받은 파일/`)에 둬요.

> **아직 못 한 것**: 받은 묶음에 `schema.sql`(v1.5)이 없어서 DB를 실제로 만들어 `verify.sql`을 돌려 보지 못했어요.
> 공유 폴더의 `database/schema.sql`은 v1.4라서 v1.5 `seed.sql` · `verify.sql`과 맞지 않아요.
> `schema.sql`(바뀌었다면 `schema_later.sql`도)을 받으면 아래 순서로 확인해요.
>
> ```
> psql -v ON_ERROR_STOP=1 -f schema.sql -f seed.sql -f verify.sql
> psql -v ON_ERROR_STOP=1 -f schema.sql -f seed.sql -f schema_later.sql -f verify.sql -f verify_later.sql
> ```

이 폴더에 있던 변경안(`v1.5_ball_catch.sql`, `v1.5_verify.sql`)은 **지웠어요**. v1.4 위에 덮어 쓰는 우리 쪽 제안이었는데,
공식 v1.5가 "던져서 잡는 볼"을 다른 모양으로 넣어서 더는 맞지 않아요 (git 기록에는 남아 있어요).

## v1.4 → v1.5 무엇이 바뀌었나

| 영역 | v1.4 | v1.5 |
|---|---|---|
| 온보딩 | `users.onboarding_step` (INTRO…DONE) | `users.onboarded_at` 하나. 온보딩 결과는 **마지막에 한 번** 저장 |
| 성실볼 | 탐색 +1회 (`EXPLORE_TICKET`, 하루 2개) | 포획용 (`CAPTURE`). 하루 상한 없음, 탐색 횟수는 늘리지 않음 |
| 탐색 1회 | 바로 결과 `MISS` / `NEW` / `DUPLICATE` | `result` = `MISS`(꽝) / `ENCOUNTER`(등장) → 등장하면 `outcome`을 한 번 정함 |
| 등장 뒤 선택 | — | `CAPTURED`(볼 1개, 개체 생김) · `ESCAPED`(볼 1개, 놓침) · `CONVERTED`(볼 없이 골드 +15) |
| 포획 확률 | — | 희귀도별 `capture_rate` = 1: 0.8 · 2: 0.6 · 3: 0.4 (임시값) |
| 같은 종 | 종당 1마리, 중복은 골드 | **여러 마리 보유 가능** (BR-54 폐지). 골드는 `CONVERTED`를 골랐을 때만 |
| 초기 몬스터 | 1마리 | **연 카테고리마다 1마리** (`starter_grant`), 대화 상대는 1마리 |
| 체크인 | 하루 1번 확정, 수정 불가 | 하루 1행 + **다시 제출 가능** (`checkin_submission`, `revision`). 최신 값만 바뀌고 골드 · 반영 습관은 **첫 확정 값 그대로** |
| 볼 사용 기록 | `monster.ball_use` | 삭제 → `explore_log.consumption_id` |
| 설정 | `duplicate_gold`, `ball_daily_max` | `convert_gold`, `capture_rate` (`ball_daily_max` 삭제) |

그대로인 것: 처리 전 등장은 사용자당 1건(다음 탐색 전에 처리), 체크인을 확정해야 탐색 횟수가 생김, 탐색 풀 = 그날 체크인한 카테고리,
볼 · 물약 소모 멱등 키는 `shop.item_consumption.consumer_key` 한 곳, 완료한 목표는 되돌리거나 지울 수 없음.

## 서버에 반영한 것

- `identity.User`: `onboarding_step` → `onboarded_at`. `PATCH /me/onboarding`은 본문 없이 완료 시각만 찍어요 (여러 번 불러도 처음 시각 유지).
- 로그인 응답의 `onboardingDone`은 그대로라 앱 화면은 바뀌지 않아요.

## 앱과 DB 규칙 맞추기 (2026-10-10 결정)

앱은 서버 없이 `GameState`가 규칙을 계산해요. v1.5와 달랐던 여섯 가지를 이렇게 정했어요.

| | 정한 규칙 | 맞춘 쪽 |
|---|---|---|
| 탐색 | 40% 확률로 아무도 안 나옴 (`explore_miss_rate`, 횟수는 씀) | **앱을 DB에** — 반영함 |
| 볼 던지기 | 희귀도별 포획 확률 0.8 / 0.6 / 0.4 (`capture_rate`) | **앱을 DB에** — 반영함 |
| 체크인 | 확정 뒤에도 다시 제출 가능. 기록만 바뀌고 보상은 첫 확정 그대로 | **앱을 DB에** — 반영함 (챗봇 "다시 체크") |
| 초기 몬스터 | 연 카테고리마다 1마리 (그림 없는 명상 · 절약은 아직 없음) | **앱을 DB에** — 반영함 |
| 이미 가진 종을 잡으면 | 볼은 쓰고, 몬스터는 늘지 않고 골드 +15 (종당 1마리) | **DB를 앱에** — 아래 요청 |
| 던지지 않을 때 | 보상 없이 넘김 ("다시 탐색" · "그만") | **DB를 앱에** — 아래 요청 |

앱 코드: `Economy.exploreMissRate` · `Economy.captureRate`, `GameState.explore / throwBall / resubmitCheckin / grantStarter`.

## DB 담당에게 요청할 변경 (v1.5 → 다음 판)

아래 두 가지는 앱 규칙을 유지하기로 해서 스키마가 바뀌어야 해요. `schema.sql` v1.5를 아직 못 받아서 SQL은 쓰지 않고 내용만 적어요.

1. **같은 종은 1마리** (BR-54 되살리기)
   - `monster.user_monster`에 사용자 × 종 유일 제약. `verify.sql`의 "v1.5 같은 종 중복 보유 가능"은 반대로 (막혀야 통과).
2. **`monster.explore_log.outcome` 값 바꾸기**: `CAPTURED` · `ESCAPED` · `CONVERTED` → `CAPTURED` · `ESCAPED` · `DUPLICATE` · `SKIPPED`

   | outcome | 뜻 | 볼(`consumption_id`) | 개체(`user_monster_id`) | 골드(`gold_awarded`) |
   |---|---|---|---|---|
   | `CAPTURED` | 던져서 잡음 (처음 얻는 종) | ○ | ○ | 0 |
   | `ESCAPED` | 던졌는데 도망 | ○ | ✗ | 0 |
   | `DUPLICATE` | 던져서 잡았는데 이미 가진 종 → 골드 | ○ | ✗ | > 0 (`convert_gold` 15) |
   | `SKIPPED` | 던지지 않고 넘김 | ✗ | ✗ | 0 |

   - `CONVERTED`(볼 없이 골드로 전환)는 없애요. 골드는 `DUPLICATE`일 때만 나오고 원장 사유는 지금의 `EXPLORE_GOLD`를 그대로 써요.
   - "처리 전 등장은 1건"은 그대로 두고, 다음 탐색을 시작하거나 탐색을 그만둘 때 남아 있는 등장을 `SKIPPED`로 마감해요.
   - `verify.sql`: "골드 전환 = 볼 없이 골드 + 원장" → "중복 포획 = 볼 소모 + 골드 + 원장", "골드 전환인데 골드 0 불가" → `DUPLICATE` 기준으로, `SKIPPED` 검사 추가.
3. (확인만) `explore_miss_rate` 0.40은 시드에 "확인 필요"로 적혀 있는데, 앱도 0.40으로 맞췄어요. 바뀌면 `Economy.exploreMissRate`도 같이 바꿔요.
