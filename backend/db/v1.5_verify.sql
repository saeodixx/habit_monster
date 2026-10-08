-- =====================================================================
-- v1.5 검증: 성실볼 = 던져서 잡는 볼
-- 실행: psql -v ON_ERROR_STOP=1 -f schema.sql -f seed.sql -f v1.5_ball_catch.sql -f v1.5_verify.sql
-- (verify.sql의 ball_use · ball_bonus · 'MISS' 관련 검사는 v1.5에서 아래 검사로 대체)
-- =====================================================================
CREATE TEMP TABLE _r (id text, ok boolean, note text);
CREATE OR REPLACE FUNCTION pg_temp.fail(_id text, _sql text) RETURNS void AS $$
BEGIN
  BEGIN EXECUTE _sql; INSERT INTO _r VALUES (_id, false, '막혀야 하는데 통과됨');
  EXCEPTION WHEN others THEN INSERT INTO _r VALUES (_id, true, SQLSTATE || ' ' || left(SQLERRM, 70)); END;
END $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION pg_temp.ok(_id text, _sql text) RETURNS void AS $$
BEGIN
  BEGIN EXECUTE _sql; INSERT INTO _r VALUES (_id, true, 'ok');
  EXCEPTION WHEN others THEN INSERT INTO _r VALUES (_id, false, SQLERRM); END;
END $$ LANGUAGE plpgsql;

-- 사용자 1명 + 체크인 → 탐색 쿼터 3회 (체크인한 카테고리: 운동·공부)
INSERT INTO identity.users (nickname) VALUES ('테스터');
INSERT INTO habit.habit_user (user_id) VALUES (1);
INSERT INTO goal.goal_user (user_id) VALUES (1);
INSERT INTO wallet.wallet (user_id) VALUES (1);
INSERT INTO monster.monster_user (user_id) VALUES (1);
INSERT INTO habit.user_category (user_id, category_code, opened_via) VALUES (1,'ex','INITIAL'),(1,'st','INITIAL');
INSERT INTO habit.daily_checkin (user_id, checkin_date, idempotency_key, habit_count, total_score, counted_score)
  VALUES (1,'2026-10-05','00000000-0000-0000-0000-000000000001',1,20,20);
INSERT INTO monster.daily_explore_quota (user_id, quota_date, base_count, source_checkin_id) VALUES (1,'2026-10-05',3,1);
INSERT INTO monster.explore_quota_category VALUES (1,'2026-10-05','ex'),(1,'2026-10-05','st');
INSERT INTO monster.user_monster (user_id, species_id, affection, location, is_partner, acquired_via)
  VALUES (1,1,3,'FIELD',true,'STARTER');                         -- 잿불 늑대 보유
INSERT INTO shop.inventory (user_id, item_code, quantity) VALUES (1,'BALL',3);

-- ---------- 구조 ----------
INSERT INTO _r SELECT 'V-1 성실볼 효과 = CATCH', effect_type = 'CATCH', effect_type FROM shop.shop_item WHERE code = 'BALL';
INSERT INTO _r SELECT 'V-2 ball_use 테이블 없음', to_regclass('monster.ball_use') IS NULL, '';
INSERT INTO _r SELECT 'V-3 쿼터에 ball_bonus 없음', count(*) = 0, ''
  FROM information_schema.columns WHERE table_schema = 'monster' AND table_name = 'daily_explore_quota' AND column_name = 'ball_bonus';
INSERT INTO _r SELECT 'V-4 config ball_daily_max 없음', count(*) = 0, '' FROM config.balance_config WHERE key = 'ball_daily_max';

-- ---------- 탐색 → 나타남 → 던지기 ----------
SELECT pg_temp.ok  ('V-10 몬스터 나타남 (FOUND)',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id)
    VALUES (1,'2026-10-05',1,'00000000-0000-0000-0000-0000000000a1','FOUND',3)$$);
SELECT pg_temp.fail('V-11 대기 중인 몬스터는 1마리 (이전 걸 마감하지 않고 또 탐색 불가)',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id)
    VALUES (1,'2026-10-05',2,'00000000-0000-0000-0000-0000000000a2','FOUND',2)$$);
SELECT pg_temp.fail('V-12 볼 없이 잡음(NEW) 불가',
  $$UPDATE monster.explore_log SET result = 'DUPLICATE', gold_awarded = 15, resolved_at = now() WHERE seq = 1$$);
SELECT pg_temp.ok  ('V-13 던져서 잡음 = 볼 소모 + 새 개체 + 결과 마감 (한 트랜잭션)',
  $$INSERT INTO shop.item_consumption (user_id, item_code, quantity, consumer_key) VALUES (1,'BALL',1,'BALL:t1');
    UPDATE shop.inventory SET quantity = quantity - 1 WHERE user_id = 1 AND item_code = 'BALL';
    INSERT INTO monster.user_monster (user_id, species_id, location, acquired_via) VALUES (1,3,'FIELD','EXPLORE');
    INSERT INTO monster.dex_entry (user_id, species_id) VALUES (1,3);
    UPDATE monster.explore_log SET result = 'NEW', resolved_at = now(),
      ball_consumption_id = (SELECT id FROM shop.item_consumption WHERE consumer_key = 'BALL:t1'),
      user_monster_id = (SELECT id FROM monster.user_monster WHERE user_id = 1 AND species_id = 3)
    WHERE seq = 1$$);
SELECT pg_temp.fail('V-14 같은 몬스터에게 두 번 던지기 불가 (결과는 한 번만)',
  $$INSERT INTO shop.item_consumption (user_id, item_code, quantity, consumer_key) VALUES (1,'BALL',1,'BALL:t2');
    UPDATE monster.explore_log SET result = 'ESCAPED', user_monster_id = NULL,
      ball_consumption_id = (SELECT id FROM shop.item_consumption WHERE consumer_key = 'BALL:t2') WHERE seq = 1$$);
SELECT pg_temp.fail('V-15 같은 볼(소모 행)을 두 탐색에 쓰기 불가',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id, ball_consumption_id, resolved_at)
    SELECT 1,'2026-10-05',2,'00000000-0000-0000-0000-0000000000a3','ESCAPED',2, id, now()
    FROM shop.item_consumption WHERE consumer_key = 'BALL:t1'$$);
SELECT pg_temp.fail('V-16 소모 행 없는 볼 번호 불가 (스키마 간 FK)',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id, ball_consumption_id, resolved_at)
    VALUES (1,'2026-10-05',2,'00000000-0000-0000-0000-0000000000a4','ESCAPED',2, 999999, now())$$);

-- ---------- 넘기기 · 도망 · 중복 ----------
SELECT pg_temp.ok  ('V-20 넘기기: FOUND → SKIPPED (볼 소모 없음)',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id)
    VALUES (1,'2026-10-05',2,'00000000-0000-0000-0000-0000000000b1','FOUND',2);
    UPDATE monster.explore_log SET result = 'SKIPPED', resolved_at = now() WHERE seq = 2$$);
SELECT pg_temp.fail('V-21 넘긴 몬스터에게 나중에 던지기 불가',
  $$INSERT INTO shop.item_consumption (user_id, item_code, quantity, consumer_key) VALUES (1,'BALL',1,'BALL:t3');
    UPDATE monster.explore_log SET result = 'ESCAPED',
      ball_consumption_id = (SELECT id FROM shop.item_consumption WHERE consumer_key = 'BALL:t3') WHERE seq = 2$$);
SELECT pg_temp.fail('V-22 넘김에는 볼이 붙을 수 없음',
  $$INSERT INTO shop.item_consumption (user_id, item_code, quantity, consumer_key) VALUES (1,'BALL',1,'BALL:t6');
    INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id, ball_consumption_id, resolved_at)
    SELECT 1,'2026-10-05',3,'00000000-0000-0000-0000-0000000000b2','SKIPPED',2, id, now()
    FROM shop.item_consumption WHERE consumer_key = 'BALL:t6'$$);
SELECT pg_temp.fail('V-23 도망인데 개체 기록 불가',
  $$INSERT INTO shop.item_consumption (user_id, item_code, quantity, consumer_key) VALUES (1,'BALL',1,'BALL:t4');
    INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id, ball_consumption_id, user_monster_id, resolved_at)
    SELECT 1,'2026-10-05',3,'00000000-0000-0000-0000-0000000000b3','ESCAPED',2, c.id, m.id, now()
    FROM shop.item_consumption c, monster.user_monster m WHERE c.consumer_key = 'BALL:t4' AND m.species_id = 1$$);
SELECT pg_temp.fail('V-24 중복인데 골드 0 불가',
  $$INSERT INTO shop.item_consumption (user_id, item_code, quantity, consumer_key) VALUES (1,'BALL',1,'BALL:t5');
    INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id, ball_consumption_id, resolved_at)
    SELECT 1,'2026-10-05',3,'00000000-0000-0000-0000-0000000000b4','DUPLICATE',1, id, now()
    FROM shop.item_consumption WHERE consumer_key = 'BALL:t5'$$);
SELECT pg_temp.fail('V-25 아무도 없음(NONE)인데 종 기록 불가',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id, resolved_at)
    VALUES (1,'2026-10-05',3,'00000000-0000-0000-0000-0000000000b5','NONE',1, now())$$);
SELECT pg_temp.fail('V-26 결과가 정해졌는데 마감 시각 없음 불가',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id)
    VALUES (1,'2026-10-05',3,'00000000-0000-0000-0000-0000000000b6','SKIPPED',2)$$);
SELECT pg_temp.fail('V-27 대기 중(FOUND)인데 마감 시각 불가',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id, resolved_at)
    VALUES (1,'2026-10-05',3,'00000000-0000-0000-0000-0000000000b7','FOUND',2, now())$$);
SELECT pg_temp.fail('V-28 결과가 정해진 뒤 만난 종 바꾸기 불가',
  $$UPDATE monster.explore_log SET species_id = 1 WHERE seq = 2$$);

-- ---------- 쿼터 ----------
SELECT pg_temp.fail('V-30 탐색 사용 횟수 > 기본 횟수 불가 (볼로 늘리지 않음)',
  $$UPDATE monster.daily_explore_quota SET used_count = 4 WHERE user_id = 1$$);
SELECT pg_temp.fail('V-31 체크인 안 한 날은 탐색 불가 (쿼터 FK 유지)',
  $$INSERT INTO monster.explore_log (user_id, quota_date, seq, idempotency_key, result, species_id)
    VALUES (1,'2026-10-09',1,'00000000-0000-0000-0000-0000000000c1','FOUND',2)$$);

-- 가방 대사: 볼 수량 = 3(시작) − 볼 소모 행 수 (V-13에서 1개만 실제로 줄임)
INSERT INTO _r SELECT 'V-40 볼 소모는 던진 횟수만큼 (성공한 던지기 1건)', count(*) = 1, count(*) || '건'
  FROM monster.explore_log WHERE ball_consumption_id IS NOT NULL;

SELECT CASE WHEN ok THEN 'PASS' ELSE 'FAIL' END AS r, id, note FROM _r ORDER BY ok, id;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM _r WHERE NOT ok) THEN RAISE EXCEPTION 'v1.5 검증 실패'; END IF; END $$;
