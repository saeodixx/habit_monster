import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/audio/bgm.dart';
import '../../core/auth/auth_service.dart';
import '../../core/constants/economy.dart';
import '../../core/state/game_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pixel_icon.dart';
import '../../core/widgets/pixel_widgets.dart';
import '../../core/widgets/popup_card.dart';
import '../../data/pixel_icons.dart';
import '../auth/auth_gate.dart';
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

  /// 셸 밖(단독 테스트 등)에서도 안전하게.
  static MainShellState? maybeOf(BuildContext context) => context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _tab = 0;
  String? _toastText;
  bool _toastCoin = false;
  Timer? _toastTimer;

  static const _tabs = ['홈', '챗봇', '통계', '도감', '목표'];

  /// 탭 안에서 잠깐 바꾸는 곡 (홈의 상점 → 상점 곡, 챗봇의 탐색 → 탐색 곡).
  final Map<int, BgmTrack> _musicOverrides = {};

  void goTab(int i) {
    setState(() => _tab = i);
    _syncMusic();
  }

  /// [tab] 안의 화면이 곡을 바꾸거나(track) 되돌린다(null). 그 탭이 보일 때만 들린다.
  void setMusicOverride(int tab, BgmTrack? track) {
    if (_musicOverrides[tab] == track) return;
    if (track == null) {
      _musicOverrides.remove(tab);
    } else {
      _musicOverrides[tab] = track;
    }
    _syncMusic();
  }

  /// 챗봇 탭은 챗봇 곡, 나머지 탭은 홈 필드 곡.
  void _syncMusic() {
    if (!mounted) return;
    final base = _tab == MainShell.chatTab ? BgmTrack.chat : BgmTrack.home;
    BgmScope.read(context).play(_musicOverrides[_tab] ?? base);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMusic());
  }

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
              const SizedBox(width: 6),
              const _SettingsButton(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(s.checkedInToday ? '탐색 ${s.encountersLeft}회 남음' : '체크인하면 탐색 ${Economy.encountersPerDay}회',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.gold)),
              const Spacer(),
              CoinChip(text: _fmt(s.gold), big: true),
              const SizedBox(width: 6),
              const _GoldInfoButton(),
              const SizedBox(width: 8),
              BallChip(count: s.balls),
            ],
          ),
        ],
      ),
    );
  }
}

/// 골드 옆 + 버튼 → 골드 얻는 법 팝업.
class _GoldInfoButton extends StatelessWidget {
  const _GoldInfoButton();

  void _open(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '골드 얻는 법 닫기',
      barrierColor: AppColors.black.withValues(alpha: 0),
      pageBuilder: (ctx, _, __) => const _GoldGuidePopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '골드 얻는 법',
      excludeSemantics: true,
      onTap: () => _open(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.ink, width: 3),
            boxShadow: const [BoxShadow(color: AppColors.fieldGreen, offset: Offset(0, 3))],
          ),
          child: const Text('+',
              style: TextStyle(fontSize: 16, height: 1, fontWeight: FontWeight.w700, color: AppColors.brownText)),
        ),
      ),
    );
  }
}

class _GoldGuidePopup extends StatelessWidget {
  const _GoldGuidePopup();

  Widget _row(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brownText)),
            const SizedBox(height: 2),
            Text(body, style: const TextStyle(fontSize: 11, height: 1.6, color: AppColors.brownMuted)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: PopupCard(
          title: '골드 얻는 법',
          ribbonColor: AppColors.purple,
          ribbonText: AppColors.white,
          maxWidth: 300,
          children: [
            GestureDetector(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _row('습관 체크하기', '챗봇에서 습관을 체크하면 성실도가 쌓이고, 성실도 1점마다 ${Economy.goldPerSincerity}골드를 받아요.'),
                  _row('성실도 레벨업', '카테고리 성실도 레벨이 오를 때마다 ${Economy.categoryLevelUpGold}골드를 받아요.'),
                  _row('목표 달성',
                      '주간 목표를 달성하면 ${Economy.weeklyGoalGold}골드, 월간 목표를 달성하면 ${Economy.monthlyGoalGold}골드를 받아요.'),
                  _row('이미 있는 몬스터', '이미 도감에 있는 몬스터를 또 만나면 ${Economy.duplicateMonsterGold}골드를 받아요.'),
                  const SizedBox(height: 4),
                  PixelButton(
                    label: '확인',
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.green,
                    shadowColor: AppColors.fieldGreen,
                    textColor: AppColors.brownText,
                    height: 42,
                    depth: 4,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상단 바 오른쪽 위 톱니바퀴 → 설정 창 (배경음악 · 계정 · 로그아웃).
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  void _open(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '설정 닫기',
      barrierColor: AppColors.black.withValues(alpha: 0),
      pageBuilder: (ctx, _, __) => _SettingsPopup(shellContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '설정',
      excludeSemantics: true,
      onTap: () => _open(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: PixelIcon(
            layers: [
              PixelLayer(PixelIcons.gear, AppColors.textMuted),
              PixelLayer(PixelIcons.gearHole, AppColors.nightDeep),
            ],
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _SettingsPopup extends StatelessWidget {
  const _SettingsPopup({required this.shellContext});
  final BuildContext shellContext;

  static const _providerName = {
    AuthProvider.email: '이메일',
    AuthProvider.kakao: '카카오',
    AuthProvider.google: 'Google',
  };

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    final auth = AuthScope.maybeRead(context);
    nav.pop();
    await auth?.signOut();
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bgm = BgmScope.of(context);
    final session = AuthScope.maybeRead(context)?.session;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: PopupCard(
          title: '설정',
          ribbonColor: AppColors.purple,
          ribbonText: AppColors.white,
          maxWidth: 290,
          children: [
            GestureDetector(
              onTap: () {}, // 카드 안을 눌러도 닫히지 않게
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('배경음악',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                      ),
                      SizedBox(
                        width: 84,
                        child: PixelButton(
                          label: bgm.enabled ? '켜짐' : '꺼짐',
                          semanticLabel: bgm.enabled ? '배경음악 끄기' : '배경음악 켜기',
                          onPressed: () => bgm.setEnabled(!bgm.enabled),
                          color: bgm.enabled ? AppColors.green : AppColors.parchment,
                          shadowColor: bgm.enabled ? AppColors.fieldGreen : AppColors.parchmentShadow,
                          textColor: AppColors.brownText,
                          height: 36,
                          depth: 3,
                          fontSize: 12,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  if (session != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      '${_providerName[session.provider]} 계정으로 로그인됨'
                      '${session.email != null ? '\n${session.email}' : ''}',
                      style: const TextStyle(fontSize: 11, height: 1.6, color: AppColors.brownMuted),
                    ),
                    const SizedBox(height: 10),
                    PixelButton(
                      label: '로그아웃',
                      onPressed: () => _logout(context),
                      color: AppColors.redSoft,
                      shadowColor: AppColors.redShadow,
                      textColor: AppColors.white,
                      height: 42,
                      depth: 4,
                      fontSize: 12,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
