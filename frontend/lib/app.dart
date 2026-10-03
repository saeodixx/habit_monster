import 'package:flutter/material.dart';

import 'core/state/game_state.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';

/// 앱 루트. 게임 상태(골드·몬스터·습관 등)를 GameScope로 하위 위젯에 내려준다.
class HabitMonsterApp extends StatefulWidget {
  const HabitMonsterApp({super.key});

  @override
  State<HabitMonsterApp> createState() => _HabitMonsterAppState();
}

class _HabitMonsterAppState extends State<HabitMonsterApp> {
  final GameState _state = GameState.sample();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScope(
      notifier: _state,
      child: MaterialApp(
        title: '습관 몬스터',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const OnboardingScreen(),
      ),
    );
  }
}
