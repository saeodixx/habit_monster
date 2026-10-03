import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/results.dart';
import '../constants/economy.dart';

/// 앱 전체 게임 상태. 지금은 메모리에만 있고, 나중에 로컬 저장소/백엔드와 연결한다.
class GameState extends ChangeNotifier {
  GameState({
    required this.gold,
    required this.balls,
    required this.monsters,
    required this.habits,
    required this.goals,
    required this.pickedCategories,
    required this.categoryPoints,
    this.encountersLeft = Economy.encountersPerDay,
    this.streakDays = 0,
    this.dayCount = 1,
    math.Random? random,
  }) : _rand = random ?? math.Random();

  final math.Random _rand;

  int gold;
  int balls;
  int encountersLeft;
  int streakDays;
  int dayCount;
  final List<OwnedMonster> monsters;
  final List<Habit> habits;
  final List<Goal> goals;
  final List<String> pickedCategories;
  final Map<String, int> categoryPoints;
  final Map<String, int> inventory = {'s': 3, 'm': 1, 'l': 0};
  String? chatPartnerUid;

  /// 오늘 챗봇으로 기록한 값 (습관 id → 값, O/X는 1/0).
  final Map<String, double> todayRecords = {};

  /// 오늘 보상을 받은 습관 (id → 그때 성실도). 다시 체크하면 기록만 고친다.
  final Map<String, int> rewardedToday = {};

  /// 디자인 시안과 같은 샘플 데이터 (DAY 12).
  factory GameState.sample({math.Random? random}) {
    final s = GameState(
      random: random,
      gold: 1240,
      balls: 1,
      streakDays: 11,
      dayCount: 12,
      pickedCategories: ['ex', 'st', 'fd'],
      categoryPoints: {'ex': 64, 'st': 38, 'fd': 21, 'md': 0, 'sl': 0, 'mn': 0},
      monsters: [
        OwnedMonster(uid: 'm1', speciesId: 'wolf', level: 7, exp: 60, affection: 4),
        OwnedMonster(uid: 'm2', speciesId: 'spark', level: 4, exp: 90, affection: 8),
        OwnedMonster(uid: 'm3', speciesId: 'sprout', level: 2, exp: 30, affection: 2),
      ],
      habits: [
        Habit(id: 'h1', name: '아침 러닝', categoryId: 'ex', measureIndex: 0, target: 30, periodIndex: 1),
        Habit(id: 'h2', name: '전공 공부', categoryId: 'st', measureIndex: 0, target: 60, periodIndex: 2),
        Habit(id: 'h3', name: '물 2L 마시기', categoryId: 'fd', measureIndex: 0, target: 2, periodIndex: 0),
      ],
      goals: [
        Goal(id: 'w1', tier: GoalTier.weekly, title: '주 3회 러닝', detail: '월·수·금 아침, 30분 이상', done: true),
        Goal(id: 'w2', tier: GoalTier.weekly, title: '전공 2챕터 끝내기', detail: '자료구조 5–6장, 연습문제까지'),
        Goal(id: 'mo1', tier: GoalTier.monthly, title: '책 2권 완독', detail: '10월 안에 소설 1권 + 에세이 1권'),
      ],
    );
    s.chatPartnerUid = 'm2';
    return s;
  }

  List<OwnedMonster> get fieldMonsters => monsters.where((m) => m.inField).toList();

  CategoryLevel categoryLevel(String categoryId) =>
      CategoryLevel.fromPoints(categoryPoints[categoryId] ?? 0);

  /// 지금 가진 개수 (물약은 가방, 성실볼은 [balls]).
  int ownedCount(ShopItem item) => item.id == Catalog.seongsilBall.id ? balls : (inventory[item.id] ?? 0);

  /// [count]개를 한 번에 산다. 골드가 모자라면 아무것도 안 하고 false.
  bool buy(ShopItem item, {int count = 1}) {
    final total = item.price * count;
    if (count < 1 || gold < total) return false;
    gold -= total;
    if (item.id == Catalog.seongsilBall.id) {
      balls += count;
    } else {
      inventory[item.id] = (inventory[item.id] ?? 0) + count;
    }
    notifyListeners();
    return true;
  }

  // ---------- 카테고리 슬롯 ----------
  /// 도감에서 발견한(가진 적 있는) 종 수.
  int get discoveredCount => monsters.map((m) => m.speciesId).toSet().length;

  /// 열 수 있는 카테고리 칸 수: 기본 3, 도감 5 · 10 · 15마리마다 +1 (카테고리 수를 넘지 않음).
  int get categorySlotCount =>
      Economy.categorySlots(discoveredCount).clamp(0, Catalog.categories.length);

  bool get canOpenCategory => pickedCategories.length < categorySlotCount;

  /// 빈 칸에 새 길을 연다.
  bool openCategory(String id) {
    if (!canOpenCategory || pickedCategories.contains(id)) return false;
    pickedCategories.add(id);
    notifyListeners();
    return true;
  }

  /// 물약을 먹인다. 올라간 레벨 수를 돌려준다 (실패 시 -1).
  int feed(OwnedMonster m, ShopItem item) {
    final have = inventory[item.id] ?? 0;
    if (have <= 0 || m.level >= Economy.finalEvolutionLevel) return -1;
    inventory[item.id] = have - 1;
    final ups = m.addExp(item.exp);
    notifyListeners();
    return ups;
  }

  // ---------- 오늘의 성실도 ----------
  /// 하루 성실도 만점 (습관 3개 × 25 = 75).
  static const int maxDailyScore = Economy.dailyHabitCap * Economy.maxSincerityPerHabit;

  List<Habit> get countedHabits => habits.take(Economy.dailyHabitCap).toList();

  Measure measureOf(Habit h) => Catalog.category(h.categoryId).measures[h.measureIndex];

  /// 오늘 기록한 값의 성실도. 기록이 없으면 null.
  int? scoreOf(Habit h) {
    final v = todayRecords[h.id];
    if (v == null) return null;
    return sincerityScore(measure: measureOf(h), target: h.target, value: v);
  }

  int get todayScore => countedHabits.fold(0, (a, h) => a + (scoreOf(h) ?? 0));
  int get checkedCount => countedHabits.where((h) => todayRecords.containsKey(h.id)).length;

  /// 상단 바의 연속 출석 (오늘 하나라도 체크하면 +1).
  int get currentStreak => streakDays + (checkedCount > 0 ? 1 : 0);

  // ---------- 습관 체크 (서버: POST /checkins) ----------
  /// 습관 하나를 기록한다. 오늘 처음이면 성실도만큼 골드와 카테고리 포인트를 주고,
  /// 카테고리 레벨이 오르면 레벨당 보너스 골드를 더 준다.
  CheckinResult recordCheckin(Habit h, double value) {
    final score = sincerityScore(measure: measureOf(h), target: h.target, value: value);
    todayRecords[h.id] = value;
    final already = rewardedToday.containsKey(h.id);
    var gold = 0;
    var ups = 0;
    final before = categoryLevel(h.categoryId).level;
    if (!already) {
      rewardedToday[h.id] = score;
      categoryPoints[h.categoryId] = (categoryPoints[h.categoryId] ?? 0) + score;
      ups = categoryLevel(h.categoryId).level - before;
      gold = score * Economy.goldPerSincerity + ups * Economy.categoryLevelUpGold;
      this.gold += gold;
    }
    notifyListeners();
    return CheckinResult(
      habit: h,
      value: value,
      score: score,
      goldEarned: gold,
      levelUps: ups,
      categoryLevel: categoryLevel(h.categoryId).level,
      alreadyRewarded: already,
    );
  }

  // ---------- 탐색 (서버: POST /explore) ----------
  /// 지금 탐색에서 만날 수 있는 종: 고른 길이고, 카테고리 레벨이 출현 레벨 이상.
  List<MonsterSpecies> get encounterPool => Catalog.species
      .where((sp) => pickedCategories.contains(sp.categoryId) && sp.unlockLevel <= categoryLevel(sp.categoryId).level)
      .toList();

  /// 탐색 1회: 고른 길의 몬스터 중 하나를 만난다 (아직 잡은 건 아님). 남은 횟수가 없으면 null.
  EncounterResult? explore() {
    if (encountersLeft <= 0) return null;
    encountersLeft -= 1;
    final pool = encounterPool;
    notifyListeners();
    if (pool.isEmpty) return const EncounterResult();
    final sp = pool[_rand.nextInt(pool.length)];
    return EncounterResult(species: sp, alreadyOwned: monsters.any((m) => m.speciesId == sp.id));
  }

  /// 만난 몬스터에게 성실볼 1개를 던진다. 볼이 없으면 null.
  /// [Economy.encounterMissRate] 확률로 도망가고, 잡았는데 이미 가진 종이면 골드로 바뀐다.
  CatchResult? throwBall(MonsterSpecies sp) {
    if (balls <= 0) return null;
    balls -= 1;
    final CatchResult result;
    if (_rand.nextDouble() < Economy.encounterMissRate) {
      result = CatchResult(kind: CatchKind.escaped, species: sp);
    } else if (monsters.any((m) => m.speciesId == sp.id)) {
      gold += Economy.duplicateMonsterGold;
      result = CatchResult(kind: CatchKind.duplicate, species: sp, gold: Economy.duplicateMonsterGold);
    } else {
      final toField = fieldMonsters.length < Economy.fieldCapacity;
      final m = OwnedMonster(uid: 'n${monsters.length}_${sp.id}', speciesId: sp.id, inField: toField);
      monsters.add(m);
      result = CatchResult(kind: CatchKind.newMonster, species: sp, monster: m, toField: toField);
    }
    notifyListeners();
    return result;
  }

  OwnedMonster? monsterByUid(String? uid) => monsters.where((m) => m.uid == uid).firstOrNull;

  // ---------- 교감 ----------
  /// 쓰다듬기 완료 (하루 1회). 실제로 오른 호감도를 돌려준다.
  int pet(OwnedMonster m) {
    final gain = math.min(Economy.petAffectionGain, Economy.maxAffection - m.affection);
    m.affection += gain;
    m.pettedToday = true;
    notifyListeners();
    return gain;
  }

  /// 놀아주기. 오늘 처음이고 호감도가 꽉 차지 않았으면 +1.
  int play(OwnedMonster m) {
    if (m.playedToday || m.affection >= Economy.maxAffection) return 0;
    m.affection += Economy.playAffectionGain;
    m.playedToday = true;
    notifyListeners();
    return Economy.playAffectionGain;
  }

  bool moveMonster(OwnedMonster m, {required bool toField}) {
    if (toField && fieldMonsters.length >= Economy.fieldCapacity) return false;
    if (!toField && fieldMonsters.length <= 1) return false;
    m.inField = toField;
    notifyListeners();
    return true;
  }

  // ---------- 목표 ----------
  /// 유료로 연 주간 목표 슬롯 (기록용, 골드 보상 없음).
  bool extraWeeklySlot = false;
  int _goalSeq = 0;

  List<Goal> goalsOf(GoalTier tier) => goals.where((g) => g.tier == tier).toList();

  int capOf(GoalTier tier) => tier == GoalTier.weekly
      ? Economy.weeklyGoalSlots + (extraWeeklySlot ? 1 : 0)
      : Economy.monthlyGoalSlots;

  /// 달성 체크를 바꾼다. 달성하면 보상 골드, 취소하면 회수.
  void toggleGoal(Goal g) {
    g.done = !g.done;
    gold += g.done ? g.reward : -g.reward;
    notifyListeners();
  }

  /// 새 목표. 무료 칸을 다 쓴 뒤의 주간 목표는 유료 슬롯(보상 없음)으로 들어간다.
  Goal addGoal(GoalTier tier, String title, String detail) {
    final paid = tier == GoalTier.weekly && goalsOf(tier).length >= Economy.weeklyGoalSlots;
    final g = Goal(id: 'g${_goalSeq++}', tier: tier, title: title, detail: detail, paidSlot: paid);
    goals.add(g);
    notifyListeners();
    return g;
  }

  void updateGoal(Goal g, String title, String detail) {
    g
      ..title = title
      ..detail = detail;
    notifyListeners();
  }

  /// 지운다. 이미 달성해서 받은 골드는 되돌린다.
  void deleteGoal(Goal g) {
    if (g.done) gold -= g.reward;
    goals.remove(g);
    notifyListeners();
  }

  void unlockExtraWeeklySlot() {
    extraWeeklySlot = true;
    notifyListeners();
  }

  /// 온보딩 1~3단계 결과를 반영한다 (시안의 `enterApp`).
  /// 길을 안 골랐거나 습관이 없으면 기존(샘플) 값을 그대로 둔다.
  void completeOnboarding({
    required List<String> picked,
    required List<Habit> habits,
    required List<Goal> goals,
    String? starterCategory,
  }) {
    if (picked.isNotEmpty) {
      pickedCategories
        ..clear()
        ..addAll(picked);
    } else if (pickedCategories.isEmpty) {
      pickedCategories.addAll(Catalog.defaultCategories);
    }
    if (habits.isNotEmpty) {
      this.habits
        ..clear()
        ..addAll(habits);
    }
    this.goals
      ..clear()
      ..addAll(goals);

    // 고르지 않은 길의 몬스터는 데리고 시작하지 않는다.
    monsters.removeWhere((m) => !pickedCategories.contains(Catalog.speciesById(m.speciesId).categoryId));
    if (monsterByUid(chatPartnerUid) == null) chatPartnerUid = monsters.firstOrNull?.uid;

    // 첫 파트너를 안 골랐는데 데려갈 몬스터가 하나도 없으면, 고른 길 중 그림이 있는 첫 후보로.
    final starterCat = starterCategory ??
        (monsters.isEmpty ? pickedCategories.where((c) => Catalog.starters[c] != null).firstOrNull : null);
    final speciesId = starterCat == null ? null : Catalog.starters[starterCat];
    if (speciesId != null) {
      var own = monsters.where((m) => m.speciesId == speciesId).firstOrNull;
      if (own == null) {
        own = OwnedMonster(
          uid: 'st_$speciesId',
          speciesId: speciesId,
          affection: Economy.starterAffection,
          inField: fieldMonsters.length < Economy.fieldCapacity,
        );
        monsters.add(own);
      }
      chatPartnerUid = own.uid;
    }
    notifyListeners();
  }

  void touch() => notifyListeners();
}

/// 위젯 트리 어디서든 `GameScope.of(context)`로 상태를 꺼내 쓰고, 바뀌면 다시 그린다.
class GameScope extends InheritedNotifier<GameState> {
  const GameScope({super.key, required GameState super.notifier, required super.child});

  static GameState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }

  /// 다시 그리기 구독 없이 읽기만 할 때 (타이머 · 버튼 콜백 안에서).
  static GameState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }
}
