import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_monster/core/state/game_state.dart';
import 'package:habit_monster/data/catalog.dart';
import 'package:habit_monster/data/results.dart';
import 'package:habit_monster/features/shell/main_shell.dart';

/// 정해진 값을 돌려주는 Random (탐색 결과 고정용).
class FixedRandom implements Random {
  FixedRandom({required this.double_, this.int_ = 0});
  final double double_;
  final int int_;
  @override
  double nextDouble() => double_;
  @override
  int nextInt(int max) => int_ % max;
  @override
  bool nextBool() => false;
}

void main() {
  group('습관 체크 규칙', () {
    test('처음 기록하면 성실도만큼 골드 · 카테고리 포인트', () {
      final s = GameState.sample();
      final run = s.habits.first; // 아침 러닝 30분 · 운동 64점 = Lv.4 (레벨 곡선 10·20·30·40)
      final r = s.recordCheckin(run, 30);
      expect(r.score, 20);
      expect(r.alreadyRewarded, isFalse);
      expect(s.todayScore, 20);
      expect(s.categoryPoints['ex'], 84);
      expect(r.categoryLevel, 4);
      expect(r.levelUps, 0);
      expect(r.goldEarned, 20);
      expect(s.gold, 1260);
    });

    test('카테고리 레벨이 오르면 레벨당 +20G', () {
      final s = GameState.sample();
      s.categoryPoints['ex'] = 95; // Lv.4, Lv.5까지 5 남음
      final r = s.recordCheckin(s.habits.first, 30);
      expect(r.levelUps, 1);
      expect(r.goldEarned, 20 + 20);
    });

    test('다시 체크하면 기록만 고치고 보상은 없다', () {
      final s = GameState.sample();
      s.recordCheckin(s.habits.first, 30);
      final gold = s.gold;
      final r = s.recordCheckin(s.habits.first, 15);
      expect(r.alreadyRewarded, isTrue);
      expect(r.goldEarned, 0);
      expect(s.gold, gold);
      expect(s.todayScore, 10);
    });
  });

  group('탐색 · 잡기 규칙', () {
    test('탐색하면 몬스터가 나타나기만 한다 (아직 안 잡음)', () {
      final s = GameState.sample(random: FixedRandom(double_: 0.9, int_: 2)); // 풀: 늑대, 쥐, 병아리, 새싹냥
      final e = s.explore()!;
      expect(e.species!.id, 'chick');
      expect(e.alreadyOwned, isFalse);
      expect(s.monsters.length, 3);
      expect(s.encountersLeft, 2);
    });

    test('만날 몬스터가 없는 길만 열었으면 아무도 없음', () {
      final s = GameState.sample();
      s.pickedCategories
        ..clear()
        ..addAll(['md', 'mn']);
      expect(s.explore()!.found, isFalse);
    });

    test('던지면 볼 1개를 쓰고 잡으면 새 몬스터', () {
      final s = GameState.sample(random: FixedRandom(double_: 0.9, int_: 2));
      final e = s.explore()!;
      final r = s.throwBall(e.species!)!;
      expect(r.kind, CatchKind.newMonster);
      expect(r.toField, isTrue);
      expect(s.balls, 0);
      expect(s.monsters.length, 4);
    });

    test('놓치면 볼만 쓰고 몬스터는 안 생긴다', () {
      final s = GameState.sample(random: FixedRandom(double_: 0.1, int_: 2));
      final r = s.throwBall(s.explore()!.species!)!;
      expect(r.kind, CatchKind.escaped);
      expect(r.caught, isFalse);
      expect(s.balls, 0);
      expect(s.monsters.length, 3);
    });

    test('이미 있는 몬스터를 잡으면 +15G', () {
      final s = GameState.sample(random: FixedRandom(double_: 0.9, int_: 0)); // 잿불 늑대
      final e = s.explore()!;
      expect(e.alreadyOwned, isTrue);
      expect(s.throwBall(e.species!)!.kind, CatchKind.duplicate);
      expect(s.gold, 1255);
    });

    test('볼이 없으면 못 던지고, 탐색 횟수가 없으면 탐색 못 함', () {
      final s = GameState.sample(random: FixedRandom(double_: 0.9));
      s.balls = 0;
      expect(s.throwBall(Catalog.speciesById('chick')), isNull);
      s.encountersLeft = 0;
      expect(s.explore(), isNull);
    });
  });

  testWidgets('챗봇: 습관 3개 체크 → 탐색', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = GameState.sample(random: FixedRandom(double_: 0.9, int_: 2));
    await tester.pumpWidget(GameScope(notifier: s, child: const MaterialApp(home: MainShell())));
    await tester.tap(find.text('챗봇'));
    await tester.pump();
    await tester.pump();

    expect(find.text('안녕! 나 찌릿 쥐. 오늘 습관 체크하러 왔어.'), findsOneWidget);
    expect(find.text("[운동] '아침 러닝' 오늘 했어?"), findsOneWidget);

    // 아침 러닝: 했어 → 빠른 선택 30분
    await tester.tap(find.text('했어!').last); // 말풍선이 아닌 버튼
    await tester.pump();
    expect(find.text('좋아! 운동 시간은 얼마나 했어? 목표는 30분이야.'), findsOneWidget);
    await tester.tap(find.text('30분'));
    await tester.pump();
    expect(find.text('성실도 +20 · +20G'), findsOneWidget);

    // 전공 공부: 못 했어
    await tester.tap(find.text('못 했어'));
    await tester.pump();
    expect(s.todayRecords['h2'], 0); // 전공 공부: 못 함 기록

    // 물 2L: 직접 입력 3
    await tester.tap(find.text('했어!').last); // 말풍선이 아닌 버튼
    await tester.pump();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('전송'));
    await tester.pump();
    await tester.pump(); // 맨 아래로 스크롤된 프레임
    expect(find.text('오늘 체크 끝! 오늘의 성실도는 45/75야. 같이 탐색하러 갈래?'), findsOneWidget);
    expect(s.todayScore, 45);
    expect(find.text('DAY 12 · 연속 12일'), findsOneWidget);

    await tester.tap(find.text('탐색하기 (3회 남음)'));
    await tester.pump();
    expect(find.textContaining('야생의 번쩍 병아리가 나타났다!'), findsOneWidget);
    expect(find.text('던지기 ×1'), findsOneWidget);
    await tester.tap(find.text('던지기 ×1'));
    await tester.pump();
    expect(find.text('성실볼을 던졌다! 과연…'), findsOneWidget);
    expect(s.balls, 0);
    // 결과 팝업을 닫기 전엔 대화 상대 줄에 안 보인다
    expect(find.bySemanticsLabel(RegExp('^번쩍 병아리와 대화')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('잡았다!'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pump();
    expect(find.text('NEW!'), findsOneWidget);
    expect(find.textContaining('번쩍 병아리(보통)를 잡았어요!'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^번쩍 병아리와 대화')), findsOneWidget);
    await tester.tap(find.text('그만'));
    await tester.pump();
    await tester.pump();
    expect(find.text('탐색하기 (2회 남음)'), findsOneWidget);
    expect(find.textContaining('번쩍 병아리를 잡았어! 새 친구가 생겼네.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });
}

