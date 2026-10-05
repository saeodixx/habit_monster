-- =====================================================================
-- v1.4 성실볼 = "던져서 잡는 볼" (schema.sql v1.3 다음에 적용)
--
-- 바뀐 게임 규칙
--   (전) 성실볼 = 오늘 탐색 +1회 (하루 2개). 탐색 1회 = 바로 결과(꽝/새 몬스터/중복)
--   (후) 탐색 1회 = 몬스터가 "나타남". 그다음 사용자가
--          · 성실볼 던지기 (볼 1개 소모) → 잡음(새 몬스터) / 잡음(중복 → 골드) / 놓침(도망)
--          · 던지지 않고 넘기기 (다시 탐색 · 그만)
--        성실볼은 하루 개수 제한 없음 (가방에 있는 만큼). 탐색 횟수는 체크인으로 받은 기본 횟수만.
--
-- 바뀌는 테이블
--   1) shop.item_effect      : 'CATCH' 추가, 성실볼 효과를 CATCH로
--   2) monster.explore_log   : 결과 값 확장 + 던진 볼(소모 행) 연결 + 결과는 한 번만 정해짐
--   3) monster.daily_explore_quota : ball_bonus 제거 (볼로 탐색 횟수를 늘리지 않음)
--   4) monster.ball_use      : 삭제 (볼 사용 기록은 explore_log.ball_consumption_id가 대신함)
--   5) config                : ball_daily_max 삭제
-- =====================================================================

-- 1) 아이템 효과 -------------------------------------------------------
INSERT INTO shop.item_effect (code, description) VALUES ('CATCH', '나타난 몬스터에게 던져 잡기');
UPDATE shop.shop_item SET effect_type = 'CATCH' WHERE code = 'BALL';
DELETE FROM shop.item_effect WHERE code = 'EXPLORE_TICKET'
  AND NOT EXISTS (SELECT 1 FROM shop.shop_item WHERE effect_type = 'EXPLORE_TICKET');

-- 2) 탐색 기록 ----------------------------------------------------------
--  한 행 = 탐색 1회. 몬스터가 나타나면 FOUND로 넣고, 사용자가 행동하면 한 번만 결과로 바꾼다.
--    NONE       아무도 없음 (고른 길에 만날 몬스터가 없음)
--    FOUND      몬스터가 나타남, 아직 아무것도 안 함
--    SKIPPED    던지지 않고 넘김 (다시 탐색 · 그만 · 다음 탐색 시 이전 FOUND를 자동 마감)
--    NEW        던져서 잡음 → 새 개체
--    DUPLICATE  던져서 잡음 → 이미 있는 종이라 골드
--    ESCAPED    던졌지만 도망
ALTER TABLE monster.explore_log
  DROP CONSTRAINT ck_explore_result,
  DROP CONSTRAINT explore_log_result_check,
  ADD COLUMN ball_consumption_id BIGINT NULL UNIQUE REFERENCES shop.item_consumption(id),  -- 볼 1개 = 던지기 1번
  ADD COLUMN resolved_at TIMESTAMPTZ NULL;

UPDATE monster.explore_log SET result = 'NONE' WHERE result = 'MISS';   -- 기존 데이터가 있다면

ALTER TABLE monster.explore_log
  ADD CONSTRAINT explore_log_result_check
    CHECK (result IN ('NONE','FOUND','SKIPPED','NEW','DUPLICATE','ESCAPED')),
  ADD CONSTRAINT ck_explore_result CHECK (
    (result = 'NONE'      AND species_id IS NULL     AND ball_consumption_id IS NULL     AND user_monster_id IS NULL     AND gold_awarded = 0) OR
    ((result = 'FOUND' OR result = 'SKIPPED')            -- IN 대신 OR: verify S-15(여러 컬럼 CHECK에 IN 금지) 규칙
                          AND species_id IS NOT NULL AND ball_consumption_id IS NULL     AND user_monster_id IS NULL     AND gold_awarded = 0) OR
    (result = 'NEW'       AND species_id IS NOT NULL AND ball_consumption_id IS NOT NULL AND user_monster_id IS NOT NULL AND gold_awarded = 0) OR
    (result = 'DUPLICATE' AND species_id IS NOT NULL AND ball_consumption_id IS NOT NULL AND user_monster_id IS NULL     AND gold_awarded > 0) OR
    (result = 'ESCAPED'   AND species_id IS NOT NULL AND ball_consumption_id IS NOT NULL AND user_monster_id IS NULL     AND gold_awarded = 0)),
  -- 결과가 정해진 행(FOUND 말고 전부)은 마감 시각이 있어야 한다
  ADD CONSTRAINT ck_explore_resolved CHECK ((result = 'FOUND') = (resolved_at IS NULL));

-- 결과는 FOUND → (SKIPPED | NEW | DUPLICATE | ESCAPED) 한 번만. 정해진 뒤엔 결과·볼·마감 시각을 못 바꾼다.
-- (CHECK는 한 행의 모양만 보므로 "두 번 던지기"를 막으려면 트리거가 필요 — goal.forbid_goal_reopen과 같은 방식)
CREATE FUNCTION monster.forbid_explore_reresolve() RETURNS trigger AS $$
BEGIN
  IF OLD.result <> 'FOUND' AND (NEW.result IS DISTINCT FROM OLD.result
       OR NEW.ball_consumption_id IS DISTINCT FROM OLD.ball_consumption_id
       OR NEW.resolved_at IS DISTINCT FROM OLD.resolved_at) THEN
    RAISE EXCEPTION 'explore % is already %', OLD.id, OLD.result USING ERRCODE = 'check_violation';
  END IF;
  IF NEW.species_id IS DISTINCT FROM OLD.species_id THEN
    RAISE EXCEPTION 'explore % species cannot change', OLD.id USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE TRIGGER tg_explore_no_reresolve BEFORE UPDATE ON monster.explore_log
  FOR EACH ROW EXECUTE FUNCTION monster.forbid_explore_reresolve();

-- 사용자당 "나타난 채 대기 중"인 몬스터는 1마리 (새로 탐색하면 이전 FOUND를 SKIPPED로 마감한 뒤 넣는다)
CREATE UNIQUE INDEX uq_explore_pending ON monster.explore_log (user_id) WHERE result = 'FOUND';

-- 3) 탐색 쿼터: 성실볼 추가 횟수 제거 ------------------------------------
ALTER TABLE monster.daily_explore_quota
  DROP CONSTRAINT ck_quota_used,
  DROP COLUMN ball_bonus,
  ADD CONSTRAINT ck_quota_used CHECK (used_count <= base_count);

-- 4) 성실볼 사용 기록 테이블 삭제 (explore_log.ball_consumption_id가 대신함) ---
DROP TABLE monster.ball_use;

-- 5) 수치 ---------------------------------------------------------------
DELETE FROM config.balance_config WHERE key = 'ball_daily_max';
