import 'models.dart';

/// 습관 하나를 기록한 결과. 백엔드 `POST /checkins` 응답과 같은 모양으로 둔다.
/// 지금은 [GameState.recordCheckin]이 로컬에서 계산하고, 서버를 붙이면 응답을 그대로 이 객체로 바꾸면 된다.
class CheckinResult {
  const CheckinResult({
    required this.habit,
    required this.value,
    required this.score,
    required this.goldEarned,
    required this.levelUps,
    required this.categoryLevel,
    required this.alreadyRewarded,
  });

  final Habit habit;

  /// 기록한 값 (O/X 습관은 1 · 0).
  final double value;

  /// 이번 기록의 성실도 (0~25).
  final int score;

  /// 이번에 받은 골드 (성실도 + 카테고리 레벨업 보너스). 이미 보상받았으면 0.
  final int goldEarned;

  /// 오른 카테고리 레벨 수.
  final int levelUps;

  /// 기록 후 카테고리 레벨.
  final int categoryLevel;

  /// 오늘 이 습관 보상을 이미 받았음 (기록만 고침).
  final bool alreadyRewarded;
}

/// 탐색 1회 결과: 몬스터를 만났는지. 백엔드 `POST /explore` 응답과 같은 모양.
/// 아직 잡은 게 아니다. 잡기는 [GameState.throwBall] → [CatchResult].
class EncounterResult {
  const EncounterResult({this.species, this.alreadyOwned = false});

  /// 만난 몬스터 종 (아무도 없었으면 null).
  final MonsterSpecies? species;

  /// 이미 가진 종인지 (잡으면 골드로 바뀐다).
  final bool alreadyOwned;

  bool get found => species != null;
}

/// 성실볼 던지기 결과: 잡음(새 몬스터) · 잡음(중복 → 골드) · 놓침(도망).
enum CatchKind { newMonster, duplicate, escaped }

/// 성실볼 1개를 던진 결과. 백엔드 `POST /explore/throw` 응답과 같은 모양.
class CatchResult {
  const CatchResult({required this.kind, required this.species, this.monster, this.toField = false, this.gold = 0});

  final CatchKind kind;
  final MonsterSpecies species;

  /// 새로 얻은 몬스터 ([CatchKind.newMonster]일 때).
  final OwnedMonster? monster;

  /// 새 몬스터가 필드로 나왔는지 (꽉 찼으면 가방).
  final bool toField;

  /// 중복으로 받은 골드.
  final int gold;

  bool get caught => kind != CatchKind.escaped;
}
