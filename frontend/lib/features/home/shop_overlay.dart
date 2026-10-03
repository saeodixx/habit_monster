import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/economy.dart';
import '../../core/state/game_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pixel_widgets.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import 'home_parts.dart';

/// 상점: 줄무늬 차양 + 상점 주인 마루 + 물약 3종 · 성실볼.
class ShopOverlay extends StatelessWidget {
  const ShopOverlay({
    super.key,
    required this.line,
    required this.bobUp,
    required this.onBuyPressed,
    required this.onClose,
  });

  /// 상점 주인 대사 (null이면 기본 인사).
  final String? line;
  final bool bobUp;
  /// 가격 버튼을 눌렀을 때 (수량 팝업은 홈이 띄운다).
  final ValueChanged<ShopItem> onBuyPressed;
  final VoidCallback onClose;

  static const _greeting = '어서 와! 비싼 물약일수록 골드당 경험치가 많아. 모아서 한 번에 사는 것도 방법이지.';
  /// 산 뒤 상점 주인 대사.
  static String reactionFor(String itemId) => _reactions[itemId] ?? _greeting;

  static const _reactions = {
    's': '고마워! 작은 물약도 꾸준히 먹이면 금방 커.',
    'm': '좋은 선택! 중급은 가성비가 괜찮지~',
    'l': '와, 상급이라니! 몬스터가 엄청 좋아할 거야.',
    'ball': '성실볼이야! 탐색에서 만난 몬스터에게 던져봐.',
  };

  @override
  Widget build(BuildContext context) {
    final s = GameScope.of(context);
    return HomeOverlay(
      onClose: onClose,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.shopCloth,
          border: Border(top: BorderSide(color: AppColors.inkBrown, width: 4)),
        ),
        child: CustomPaint(
          painter: const _ClothLines(),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 36, width: double.infinity, child: CustomPaint(painter: _AwningPainter())),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Keeper(line: line ?? _greeting, bobUp: bobUp),
                          for (final it in [...Catalog.items, Catalog.seongsilBall]) ...[
                            const SizedBox(height: 10),
                            _ItemRow(
                              item: it,
                              owned: it.id == Catalog.seongsilBall.id ? s.balls : (s.inventory[it.id] ?? 0),
                              canBuy: s.gold >= it.price,
                              onBuy: () => onBuyPressed(it),
                            ),
                          ],
                          const SizedBox(height: 10),
                          const Text(
                            '물약은 몬스터 정보에서 사용 · 레벨당 ${Economy.expPerLevel} EXP · '
                            'Lv.${Economy.firstEvolutionLevel} 1차 진화, Lv.${Economy.finalEvolutionLevel} 최종 진화',
                            style: TextStyle(fontSize: 9.5, height: 1.8, color: AppColors.footnoteBrown),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 간판
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.woodDark,
                      border: Border.all(color: AppColors.inkBrown, width: 4),
                      boxShadow: const [BoxShadow(color: AppColors.woodDeep, offset: Offset(0, 4))],
                    ),
                    child: const Text('상점',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.paper,
                          shadows: [Shadow(color: AppColors.woodDeep, offset: Offset(2, 2))],
                        )),
                  ),
                ),
              ),
              Positioned(right: 10, top: 8, child: BrownCloseButton(onTap: onClose)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 천 무늬: 26px마다 3px 가로줄.
class _ClothLines extends CustomPainter {
  const _ClothLines();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.shopClothLine;
    for (double y = size.height - 3; y > -3; y -= 26) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 빨강/크림 줄무늬 차양(30px) + 아래 톱니(6px).
class _AwningPainter extends CustomPainter {
  const _AwningPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()..color = AppColors.redSoft;
    final cream = Paint()..color = AppColors.parchment;
    for (double x = 0; x < size.width; x += 52) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 26, 30), red);
      canvas.drawRect(Rect.fromLTWH(x + 26, 0, 26, 30), cream);
      canvas.drawRect(Rect.fromLTWH(x, 30, 13, 6), red);
      canvas.drawRect(Rect.fromLTWH(x + 26, 30, 13, 6), cream);
    }
    canvas.drawRect(Rect.fromLTWH(0, 26, size.width, 4), Paint()..color = AppColors.inkBrown);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Keeper extends StatelessWidget {
  const _Keeper({required this.line, required this.bobUp});
  final String line;
  final bool bobUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 86,
          height: 118,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                bottom: -38 + (bobUp ? 4 : 0),
                child: const PixelImage(AppAssets.shopkeeper, height: 150),
              ),
              // 계산대
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 16,
                  alignment: Alignment.topCenter,
                  decoration: const BoxDecoration(
                    color: AppColors.wood,
                    border: Border(
                      top: BorderSide(color: AppColors.inkBrown, width: 3),
                      left: BorderSide(color: AppColors.inkBrown, width: 3),
                      right: BorderSide(color: AppColors.inkBrown, width: 3),
                    ),
                  ),
                  child: Container(height: 3, color: AppColors.woodLight),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    border: Border.all(color: AppColors.inkBrown, width: 3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('상점 주인 마루',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.red)),
                      const SizedBox(height: 2),
                      Text(line, style: const TextStyle(fontSize: 11.5, height: 1.8, color: AppColors.brownText)),
                    ],
                  ),
                ),
                Positioned(
                  left: -6,
                  bottom: 15,
                  child: Container(
                    width: 9,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      border: Border(
                        left: BorderSide(color: AppColors.inkBrown, width: 3),
                        top: BorderSide(color: AppColors.inkBrown, width: 3),
                        bottom: BorderSide(color: AppColors.inkBrown, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.owned, required this.canBuy, required this.onBuy});
  final ShopItem item;
  final int owned;
  final bool canBuy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final isBall = item.id == Catalog.seongsilBall.id;
    final desc = isBall
        ? '탐색에서 만난 몬스터에게 던져서 잡아요 · 1번에 1개'
        : '+${item.exp} EXP · 골드당 효율 ${item.goldEfficiency.toStringAsFixed(2)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.inkBrown, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.tanShadow, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(border: Border.all(color: AppColors.inkBrown, width: 3)),
            child: CustomPaint(
              painter: const CheckerPainter(AppColors.checker, AppColors.offWhite),
              child: Center(child: PixelImage(item.asset, height: 34)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 10, height: 1.5, color: AppColors.brownMuted)),
                const SizedBox(height: 4),
                Container(
                  color: AppColors.woodDark,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text('보유 $owned개', style: const TextStyle(fontSize: 9.5, color: AppColors.paper)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          SizedBox(
            width: 76,
            child: PixelButton(
              label: '${item.price}G',
              onPressed: canBuy ? onBuy : null,
              height: 44,
              depth: 4,
              color: AppColors.yellowButton,
              shadowColor: AppColors.yellowShadow,
              borderColor: AppColors.inkBrown,
              padding: EdgeInsets.zero,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CoinIcon(color: canBuy ? AppColors.gold : AppColors.disabledShadow),
                    const SizedBox(width: 5),
                    Text('${item.price}G',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: canBuy ? AppColors.brownText : AppColors.disabledText)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
