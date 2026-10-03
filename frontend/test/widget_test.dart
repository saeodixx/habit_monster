import 'package:flutter_test/flutter_test.dart';

import 'package:habit_monster/data/models.dart';

void main() {
  test('카테고리 레벨 곡선 10×N', () {
    expect(CategoryLevel.fromPoints(0).level, 1);
    expect(CategoryLevel.fromPoints(10).level, 2);
    expect(CategoryLevel.fromPoints(30).level, 3);
  });

  test('성실도 계산', () {
    const m = Measure('운동 시간', '분', 30);
    expect(sincerityScore(measure: m, target: 30, value: 30), 20);
    expect(sincerityScore(measure: m, target: 30, value: 15), 10);
    expect(sincerityScore(measure: m, target: 30, value: 90), 25);
  });

  test('경험치 125마다 레벨업', () {
    final mon = OwnedMonster(uid: 't', speciesId: 'wolf', level: 9, exp: 100);
    expect(mon.addExp(30), 1);
    expect(mon.stage, '1차 진화');
  });
}
