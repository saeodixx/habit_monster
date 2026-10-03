import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_monster/core/state/game_state.dart';
import 'package:habit_monster/data/models.dart';
import 'package:habit_monster/features/shell/main_shell.dart';

void main() {
  group('GameState 목표', () {
    test('달성 체크 시 골드 지급, 취소하면 회수', () {
      final s = GameState.sample();
      final g = s.goalsOf(GoalTier.monthly).single;
      s.toggleGoal(g);
      expect(s.gold, 1240 + 150);
      s.toggleGoal(g);
      expect(s.gold, 1240);
    });

    test('달성한 목표를 지우면 받은 골드를 되돌린다', () {
      final s = GameState.sample();
      final done = s.goals.firstWhere((g) => g.done); // 주 3회 러닝 (+40 받은 상태)
      s.deleteGoal(done);
      expect(s.gold, 1200);
    });

    test('무료 3칸 뒤의 주간 목표는 유료 슬롯 · 보상 0', () {
      final s = GameState.sample(); // 주간 2개
      final third = s.addGoal(GoalTier.weekly, '세 번째', '');
      expect(third.reward, 40);
      expect(s.capOf(GoalTier.weekly), 3);
      s.unlockExtraWeeklySlot();
      expect(s.capOf(GoalTier.weekly), 4);
      final fourth = s.addGoal(GoalTier.weekly, '네 번째', '');
      expect(fourth.paidSlot, isTrue);
      expect(fourth.reward, 0);
    });
  });

  testWidgets('목표 탭: 체크 · 추가 · 수정 · 삭제', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = GameState.sample();
    await tester.pumpWidget(GameScope(notifier: s, child: const MaterialApp(home: MainShell())));
    await tester.tap(find.text('목표'));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('책 2권 완독 달성 체크'));
    await tester.pump();
    expect(s.gold, 1390);

    // 빈 제목은 저장 안 됨
    await tester.tap(find.textContaining('+ 목표 추가'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(find.text('목표를 적어주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '매일 스트레칭');
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(find.text('매일 스트레칭'), findsOneWidget);
    expect(find.text('슬롯 추가 열기 (유료 · 기록용)'), findsOneWidget);

    // 수정 → 삭제
    await tester.tap(find.bySemanticsLabel('목표 수정').at(2));
    await tester.pump();
    expect(find.text('목표 수정'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pump();
    expect(find.text('매일 스트레칭'), findsNothing);
    await tester.pump(const Duration(seconds: 7));
  });
}
