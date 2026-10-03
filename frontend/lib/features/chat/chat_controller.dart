import 'package:flutter/foundation.dart';

import '../../core/constants/economy.dart';
import '../../core/state/game_state.dart';
import '../../core/utils/format.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/results.dart';
import 'chat_brain.dart';

/// 대화 단계: 시작 전 · 했어/못 했어 · 수행량 입력 · 체크 끝 · 탐색 화면.
enum ChatStep { idle, yesNo, amount, done, explore }

class ChatMessage {
  const ChatMessage.bot(this.text, {this.reward, this.levelUp}) : fromBot = true;
  const ChatMessage.me(this.text)
      : fromBot = false,
        reward = null,
        levelUp = null;

  final bool fromBot;
  final String text;

  /// 보상 칩 (예: 성실도 +20 · +20G).
  final String? reward;

  /// 카테고리 레벨업 칩.
  final String? levelUp;
}

/// 습관 체크 대화의 흐름. 앞에서부터 [Economy.dailyHabitCap]개 습관을 차례로 묻는다.
/// 말은 [ChatBrain]이, 규칙 계산은 [GameState]가 한다.
class ChatController extends ChangeNotifier {
  ChatController({required this.state, this.brain = const ScriptedChatBrain()});

  final GameState state;
  final ChatBrain brain;

  final List<ChatMessage> messages = [];
  ChatStep step = ChatStep.idle;
  int _habitIndex = 0;

  /// 챗봇이 대답을 만드는 중 (AI 연결 시 입력을 막고 "…"을 보여준다).
  bool busy = false;

  /// 마지막 탐색에서 만난 몬스터.
  EncounterResult? encounter;

  /// 그 몬스터에게 던진 성실볼 결과 (아직 안 던졌으면 null).
  CatchResult? lastCatch;

  bool _disposed = false;

  List<Habit> get _habits => state.countedHabits;
  Habit? get currentHabit => _habitIndex < _habits.length ? _habits[_habitIndex] : null;
  Measure? get currentMeasure => currentHabit == null ? null : state.measureOf(currentHabit!);

  /// 수행량 빠른 선택: 점수형은 3·4·5, 나머지는 목표의 50% · 100% · 150%.
  List<double> get quickAmounts {
    final h = currentHabit;
    final m = currentMeasure;
    if (h == null || m == null || m.isOX) return const [];
    if (m.unit == '점') return const [3, 4, 5];
    double r1(double v) => (v * 10).round() / 10;
    return [r1(h.target * 0.5) < 1 ? 1 : r1(h.target * 0.5), h.target, r1(h.target * 1.5)];
  }

  /// 대화 상대 (몬스터가 하나도 없으면 null).
  OwnedMonster? get partner => state.monsterByUid(state.chatPartnerUid) ?? state.monsters.firstOrNull;

  /// 방금 잡았지만 아직 결과 팝업을 닫지 않은 몬스터 (대화 상대 줄에서 잠깐 숨긴다).
  String? hiddenMonsterUid;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<T> _think<T>(Future<T> f) async {
    busy = true;
    _notify();
    try {
      return await f;
    } finally {
      busy = false;
    }
  }

  /// 대화를 처음부터 (대화 상대가 바뀌거나 "다시 체크").
  Future<void> start() async {
    messages.clear();
    encounter = null;
    final p = partner;
    final sp = p == null ? null : Catalog.speciesById(p.speciesId);
    messages.add(ChatMessage.bot(await _think(brain.greet(sp))));
    await _ask(0);
  }

  Future<void> _ask(int i) async {
    _habitIndex = i;
    final h = currentHabit;
    if (h == null) {
      final text = await _think(brain.wrapUp(todayScore: state.todayScore, maxScore: GameState.maxDailyScore));
      messages.add(ChatMessage.bot(text));
      step = ChatStep.done;
    } else {
      messages.add(ChatMessage.bot(await _think(brain.askHabit(h, Catalog.category(h.categoryId)))));
      step = ChatStep.yesNo;
    }
    _notify();
  }

  /// 했어 / 못 했어.
  Future<void> answer(bool yes) async {
    final h = currentHabit;
    if (h == null || step != ChatStep.yesNo || busy) return;
    messages.add(ChatMessage.me(yes ? '했어!' : '못 했어…'));
    if (!yes) return _record(0);
    final m = state.measureOf(h);
    if (m.isOX) return _record(1);
    messages.add(ChatMessage.bot(await _think(brain.askAmount(h, m))));
    step = ChatStep.amount;
    _notify();
  }

  /// 수행량 보내기. 숫자가 아니면 false.
  Future<bool> sendAmount(String raw) async {
    final v = double.tryParse(raw.trim());
    if (v == null || v < 0) return false;
    await sendValue(v);
    return true;
  }

  Future<void> sendValue(double v) async {
    final m = currentMeasure;
    if (m == null || step != ChatStep.amount || busy) return;
    messages.add(ChatMessage.me('${formatNum(v)}${m.unit}'));
    await _record(v);
  }

  Future<void> _record(double v) async {
    final r = state.recordCheckin(currentHabit!, v);
    final text = await _think(brain.react(r));
    final rewarded = !r.alreadyRewarded && r.score > 0;
    final cat = Catalog.category(r.habit.categoryId);
    messages.add(ChatMessage.bot(
      text,
      reward: rewarded ? '성실도 +${r.score} · +${r.score * Economy.goldPerSincerity}G' : null,
      levelUp: rewarded && r.levelUps > 0
          ? '${cat.name} Lv.${r.categoryLevel} 달성! +${r.levelUps * Economy.categoryLevelUpGold}G'
          : null,
    ));
    await _ask(_habitIndex + 1);
  }

  // ---------- 탐색 ----------
  /// 탐색 1회: 몬스터가 나타난다 (아직 안 잡음).
  void explore() {
    final r = state.explore();
    if (r == null) return;
    encounter = r;
    lastCatch = null;
    step = ChatStep.explore;
    _notify();
  }

  /// 지금 나타난 몬스터에게 성실볼을 던질 수 있는지 (이미 던졌으면 끝).
  bool get canThrow => encounter?.found == true && lastCatch == null;

  /// 성실볼 1개를 던진다. 볼이 없거나 던질 대상이 없으면 null.
  /// 잡았으면 대화창에도 남긴다 (놓치면 남기지 않음).
  Future<CatchResult?> throwBall() async {
    if (!canThrow) return null;
    final r = state.throwBall(encounter!.species!);
    if (r == null) return null;
    lastCatch = r;
    hiddenMonsterUid = r.monster?.uid;
    _notify();
    if (r.caught) messages.add(ChatMessage.bot(await brain.catchReport(r)));
    return r;
  }

  /// 잡기 결과 팝업을 닫았다.
  void confirmCatch() {
    hiddenMonsterUid = null;
    _notify();
  }

  void leaveExplore() {
    step = ChatStep.done;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
