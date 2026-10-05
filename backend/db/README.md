# DB 변경안 v1.4 — 성실볼을 "던져서 잡는 볼"로

원본 설계(`schema.sql` v1.3, `verify.sql`)는 그대로 두고, 그 위에 덮어 적용하는 파일입니다.

```
psql -v ON_ERROR_STOP=1 -f schema.sql -f seed.sql -f v1.4_ball_catch.sql -f v1.4_verify.sql
```

PostgreSQL 18 임시 DB에서 `schema.sql` → (앱 카탈로그로 만든 임시 시드) → `v1.4_ball_catch.sql` → `v1.4_verify.sql` 순서로 돌려 **23개 검사 모두 통과**를 확인했습니다. `schema_later.sql`을 함께 적용해도 같습니다.

## 무엇이 바뀌나 (한눈에)

| | v1.3 (지금 설계) | v1.4 (앱과 같은 규칙) |
|---|---|---|
| 성실볼 | 오늘 탐색 +1회 (하루 2개까지) | 나타난 몬스터에게 던지는 볼. 던질 때마다 1개, 하루 제한 없음 |
| 탐색 1회 | 바로 결과: 꽝 / 새 몬스터 / 중복 | 몬스터가 **나타남** → 던지기 or 넘기기 |
| 탐색 결과 | `MISS` `NEW` `DUPLICATE` | `NONE`(아무도 없음) `FOUND`(나타남, 대기) `SKIPPED`(넘김) `NEW` `DUPLICATE` `ESCAPED`(도망) |
| 볼 사용 기록 | `monster.ball_use` 테이블 | `explore_log.ball_consumption_id` (어느 탐색에 던졌는지 바로 연결) |
| 탐색 횟수 | 기본 + 볼 추가분 (`ball_bonus`) | 기본만 (체크인 확정 때 받은 횟수) |

## 테이블별로

1. **`shop.item_effect` / `shop.shop_item`** — 효과 코드 `CATCH` 추가, 성실볼(`BALL`)의 효과를 `CATCH`로. `EXPLORE_TICKET`은 쓰는 아이템이 없으면 삭제.
2. **`monster.explore_log`** (핵심)
   - 탐색하면 몬스터가 나타난 상태(`FOUND`)로 한 줄 넣고, 사용자가 행동하면 **그 줄의 결과를 한 번만** 바꿉니다.
   - 새 컬럼 `ball_consumption_id` → `shop.item_consumption(id)`, UNIQUE: 볼 1개로는 한 번만 던질 수 있음.
   - 새 컬럼 `resolved_at`: 결과가 정해진 시각 (`FOUND`일 때만 비어 있음).
   - 결과별로 들어가야 하는 값 (CHECK):

     | 결과 | 종 | 볼 | 새 개체 | 골드 |
     |---|---|---|---|---|
     | NONE | ✗ | ✗ | ✗ | 0 |
     | FOUND / SKIPPED | ○ | ✗ | ✗ | 0 |
     | NEW | ○ | ○ | ○ | 0 |
     | DUPLICATE | ○ | ○ | ✗ | > 0 |
     | ESCAPED | ○ | ○ | ✗ | 0 |

   - 트리거 `tg_explore_no_reresolve`: 결과가 정해진 뒤에는 결과·볼·시각·종을 못 바꿈 → **같은 몬스터에 두 번 던지기, 넘긴 몬스터에 나중에 던지기를 DB가 막음** (목표의 `forbid_goal_reopen`과 같은 방식).
   - 부분 유니크 인덱스 `uq_explore_pending`: 사용자당 대기 중(`FOUND`) 몬스터는 1마리. 새로 탐색할 땐 이전 `FOUND`를 `SKIPPED`로 마감한 뒤 넣습니다.
3. **`monster.daily_explore_quota`** — `ball_bonus` 컬럼 삭제, `used_count ≤ base_count`.
4. **`monster.ball_use`** — 테이블 삭제.
5. **`config.balance_config`** — `ball_daily_max` 삭제.

그대로인 것: 체크인 확정 때만 쿼터가 생김(체크인 안 하면 탐색 불가), 탐색 풀은 그날 체크인한 카테고리(`explore_quota_category`), 종당 1마리(중복은 골드), 볼 소모 멱등 키 `consumer_key`.

## 서버 처리 순서 (F7 탐색 · 새 F8 던지기)

- **탐색** `POST /explore`: 쿼터 잠금 → 이전 `FOUND`가 있으면 `SKIPPED`로 마감 → `used_count + 1` → 풀에서 종 뽑기 → `FOUND`(또는 `NONE`) INSERT.
- **던지기** `POST /explore/throw`: 가방 볼 −1 + `item_consumption`(consumer_key `BALL:<uuid>`) → 도망 확률(`explore_miss_rate`) 판정 → `NEW`면 개체·도감 추가(+해금권 기준 달성 시 지급) / `DUPLICATE`면 지갑 +15G (원장 `DUPLICATE`, ref_id = explore_log.id) → explore_log 결과 UPDATE. 모두 한 트랜잭션.
- **넘기기**: `FOUND` → `SKIPPED` UPDATE (볼·골드 변화 없음).

## `verify.sql`에서 고칠 곳 (v1.4 적용 후 실패하는 3개 + 의미가 없어지는 4개)

| 검사 | 처리 |
|---|---|
| S-1 스키마 간 FK 허용 목록 | `('monster.ball_use','shop.item_consumption')` → `('monster.explore_log','shop.item_consumption')` 로 교체 (개수는 15개 그대로) |
| 성실볼 = 소모 1건 + 사용 기록 + 추가 횟수 | 삭제 → `v1.4_verify.sql` V-13 |
| 성실볼 재시도: 같은 소모 키는 소모 단계에서 차단 | 위 검사가 만들던 `BALL:u1`이 없어져서 실패. V-13 다음에 같은 키 재삽입으로 옮기거나 삭제 (소모 키 UNIQUE는 "소모 키 재사용 차단" 검사가 이미 확인) |
| 같은 소모 행으로 성실볼 두 번 반영 불가 · 소모 행 없이 성실볼 기록 불가 · 쿼터 없는 날 성실볼 사용 불가 | `ball_use`가 없어서 **잘못된 이유로 PASS** 됨 → 삭제 (V-15, V-16, V-31이 대신) |
| 꽝인데 종 기록 불가 | `'MISS'` → `'NONE'`, `resolved_at` 값 추가 (V-25와 같음) |
| BR-50 사용 횟수 > 기본 + 성실볼 불가 | 이름만 "사용 횟수 > 기본 불가"로 (V-30) |

`04_논리물리모델.md`의 F6(성실볼 사용) 절과 업무 규칙 표의 "성실볼 하루 ≤ 2" 줄도 위 내용으로 바꾸면 됩니다.
