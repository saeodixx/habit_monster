import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoon(title: '통계', todo: [
      '연속 출석 + 최근 14일 칸',
      '최근 7일 성실도 막대그래프',
      '카테고리별 레벨과 다음 레벨까지 남은 성실도',
    ]);
  }
}
