import 'package:flutter/material.dart';

import 'core/audio/bgm.dart';
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
  final Bgm _bgm = AudioBgm();

  @override
  void dispose() {
    _state.dispose();
    _bgm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScope(
      notifier: _state,
      child: BgmScope(
        notifier: _bgm,
        // 웹은 사용자가 화면을 누르기 전엔 소리를 막으므로, 첫 터치 때 배경음악을 다시 시도한다.
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _bgm.unlock(),
          child: MaterialApp(
            title: '습관 몬스터',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(),
            home: const OnboardingScreen(),
          ),
        ),
      ),
    );
  }
}
