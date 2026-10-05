import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/economy.dart';
import '../../core/state/game_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pixel_icon.dart';
import '../../core/widgets/pixel_widgets.dart';
import '../../data/pixel_icons.dart';
import '../chat/chat_screen.dart';
import '../dex/dex_screen.dart';
import '../goals/goals_screen.dart';
import '../home/home_screen.dart';
import '../stats/stats_screen.dart';

/// 상단 바(날짜 · 탐색 · 골드 · 성실볼) + 본문 + 하단 탭 5개.
///
/// 하위 화면에서 `MainShell.of(context)`로 탭 이동([MainShellState.goTab])과
/// 토스트([MainShellState.toast])를 쓸 수 있다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const int homeTab = 0;
  static const int chatTab = 1;
  static const int dexTab = 3;

  static MainShellState of(BuildContext context) => context.findAncestorStateOfType<MainShellState>()!;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _tab = 0;
  String? _toastText;
  bool _toastCoin = false;
  Timer? _toastTimer;

  static const _tabs = ['홈', '챗봇', '통계', '도감', '목표'];

  void goTab(int i) => setState(() => _tab = i);

  /// 본문 위쪽 가운데에 1.8초 동안 알림을 띄운다. [coin]이면 금화 아이콘을 붙인다.
  void toast(String text, {bool coin = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toastText = text;
      _toastCoin = coin;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toastText = null);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IndexedStack(
                      index: _tab,
                      children: [
                        HomeScreen(active: _tab == MainShell.homeTab),
                        ChatScreen(active: _tab == MainShell.chatTab),
                        const StatsScreen(),
                        DexScreen(active: _tab == MainShell.dexTab),
                        const GoalsScreen(),
                      ],
                    ),
                  ),
                  if (_toastText != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 14,
                      child: IgnorePointer(child: Center(child: PixelToast(text: _toastText!, coin: _toastCoin))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.nightDeep,
          border: Border(top: BorderSide(color: AppColors.nightLine, width: 3)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => goTab(i),
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _tab == i ? AppColors.gold : Colors.transparent, width: 3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PixelIcon(
                            layers: [PixelLayer(PixelIcons.nav[i], _tab == i ? AppColors.gold : AppColors.textMuted)],
                            size: 20,
                          ),
                          const SizedBox(height: 5),
                          Text(_tabs[i],
                              style: TextStyle(fontSize: 10.5, color: _tab == i ? AppColors.gold : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  static const _weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

  String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) {
    final s = GameScope.of(context);
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: const BoxDecoration(
        color: AppColors.nightDeep,
        border: Border(bottom: BorderSide(color: AppColors.nightLine, width: 3)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${now.month}월 ${now.day}일',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, shadows: [
                    Shadow(color: AppColors.nightLine, offset: Offset(3, 3)),
                  ])),
              const SizedBox(width: 8),
              Text(_weekdays[now.weekday - 1], style: const TextStyle(fontSize: 13, color: AppColors.purpleSoft)),
              const Spacer(),
              Text('DAY ${s.dayCount} · 연속 ${s.currentStreak}일',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(s.checkedInToday ? '탐색 ${s.encountersLeft}회 남음' : '체크인하면 탐색 ${Economy.encountersPerDay}회',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.gold)),
              const Spacer(),
              CoinChip(text: _fmt(s.gold), big: true),
              const SizedBox(width: 8),
              BallChip(count: s.balls),
            ],
          ),
        ],
      ),
    );
  }
}
