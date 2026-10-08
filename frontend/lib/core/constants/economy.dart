/// 진화 경제 수치 v1 (docs/economy-v1.md). 모두 [추후튜닝] 대상.
class Economy {
  Economy._();

  // 시작 자원
  static const int startingGold = 50;
  static const int startingBalls = 3;

  // 수입
  static const int goldPerSincerity = 1;
  static const int dailyHabitCap = 3; // 하루 성실도에 반영되는 습관 수 (점수 상위 3개)
  static const int maxActiveHabits = 5; // 활성 습관 상한 (챗봇은 전부 묻는다)
  static const int maxSincerityPerHabit = 25; // 습관 1개당 최대 성실도
  static const int categoryLevelUpGold = 20;
  static const int weeklyGoalGold = 40;
  static const int monthlyGoalGold = 150;
  static const int duplicateMonsterGold = 15;

  // 지출 / 탐색
  static const int seongsilBallPrice = 50; // 던질 때마다 1개
  static const int encountersPerDay = 3;
  static const double encounterMissRate = 0.35; // 성실볼을 던졌을 때 몬스터가 빠져나와 도망갈 확률

  // 몬스터 성장
  static const int expPerLevel = 125;
  static const int firstEvolutionLevel = 10;
  static const int finalEvolutionLevel = 20;
  static const int fieldCapacity = 5;

  // 호감도
  static const int maxAffection = 10;
  static const int petAffectionGain = 2; // 하루 1회
  static const int playAffectionGain = 1; // 하루 1회
  static const int starterAffection = 3; // 온보딩에서 고른 첫 파트너

  // 카테고리 슬롯: 기본 3개, 도감 발견 5 · 10 · 15마리마다 +1 (최대 6)
  static const int baseCategorySlots = 3;
  static const List<int> categorySlotSteps = [5, 10, 15];
  static int categorySlots(int discovered) =>
      baseCategorySlots + categorySlotSteps.where((n) => discovered >= n).length;

  // 목표 슬롯
  static const int weeklyGoalSlots = 3;
  static const int monthlyGoalSlots = 1;
}
