import 'package:flutter/material.dart';

import '../../core/constants/economy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pixel_icon.dart';
import '../../core/widgets/pixel_widgets.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/pixel_icons.dart';
import 'onboarding_controller.dart';
import 'onboarding_parts.dart';

/// 온보딩 3단계: 목표 보상 안내 + 주간/월간 목표 적기.
class StepGoals extends StatelessWidget {
  const StepGoals({super.key, required this.c, required this.onEnter});
  final OnboardingController c;

  /// 홈으로 들어가기 (건너뛰기와 같다).
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      bottom: Row(
        children: [
          SizedBox(
            width: 92,
            child: PixelButton(
              label: '건너뛰기',
              onPressed: onEnter,
              color: AppColors.parchment,
              shadowColor: AppColors.parchmentShadow,
              textColor: AppColors.brownText,
              fontSize: 12,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: PixelButton(label: c.goalCount > 0 ? '모험 시작 ▶' : '목표 없이 시작 ▶', onPressed: onEnter),
          ),
        ],
      ),
      children: [
        const StepHeader(step: 3, title: '목표 세우기'),
        const ProfessorTip(text: '목표를 세워두면 몬스터를 강하게 키우는 가장 빠른 길이 된다네!'),
        const _RewardTable(),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RibbonPanel(
            title: '내 목표 적기',
            ribbonColor: AppColors.purple,
            children: [
              _GoalSection(c: c, tier: GoalTier.weekly),
              _GoalSection(c: c, tier: GoalTier.monthly),
              const Text('상세 내용은 나중에 목표 탭에서 언제든 고칠 수 있어요.',
                  style: TextStyle(fontSize: 9.5, color: AppColors.brownMuted)),
            ],
          ),
        ),
        Center(
          child: Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: c.toggleShopPreview,
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  c.showShopPreview ? '골드로 살 수 있는 것 접기 ▲' : '골드로 살 수 있는 것은? ▼',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.butter,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.butter,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (c.showShopPreview) const _ShopPreview(),
      ],
    );
  }
}

class _RewardTable extends StatelessWidget {
  const _RewardTable();

  @override
  Widget build(BuildContext context) {
    final (lid, body, band) = PixelIcons.chestColors[2];
    return RibbonPanel(
      title: '목표 보상표',
      gap: 12,
      children: [
        _RewardRow(
          color: AppColors.skyCard,
          shadow: AppColors.skyCardShadow,
          subColor: AppColors.skyCardText,
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < Economy.weeklyGoalSlots; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                const PixelIcon(layers: PixelIcons.weeklyChest, size: 22, outline: 1),
              ],
            ],
          ),
          title: '주간 목표',
          count: '최대 ${Economy.weeklyGoalSlots}개',
          desc: '달성할 때마다 보상 · 슬롯 추가는 유료',
          reward: '+${Economy.weeklyGoalGold}G',
        ),
        _RewardRow(
          color: AppColors.butter,
          shadow: AppColors.yellowShadow,
          subColor: AppColors.butterText,
          icon: PixelIcon(layers: PixelIcons.chest(lid, body, band, highlight: false), size: 40, outline: 1.5),
          title: '월간 목표',
          count: '${Economy.monthlyGoalSlots}개',
          desc: '한 달에 한 번, 큰 보물상자!',
          reward: '+${Economy.monthlyGoalGold}G',
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.color,
    required this.shadow,
    required this.subColor,
    required this.icon,
    required this.title,
    required this.count,
    required this.desc,
    required this.reward,
  });
  final Color color;
  final Color shadow;
  final Color subColor;
  final Widget icon;
  final String title;
  final String count;
  final String desc;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.ink, width: 3),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$title '),
                    TextSpan(
                      text: count,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: subColor),
                    ),
                  ]),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brownText),
                ),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 10, color: subColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(reward, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.goldDeep)),
        ],
      ),
    );
  }
}

class _GoalSection extends StatelessWidget {
  const _GoalSection({required this.c, required this.tier});
  final OnboardingController c;
  final GoalTier tier;

  @override
  Widget build(BuildContext context) {
    final weekly = tier == GoalTier.weekly;
    final list = c.goals[tier]!;
    final cap = OnboardingController.capOf(tier);
    final name = weekly ? '주간 목표' : '월간 목표';
    final reward = weekly ? '개당 +${Economy.weeklyGoalGold}G' : '+${Economy.monthlyGoalGold}G';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NumberedLabel(badge: name, title: '', hint: '${list.length}/$cap · $reward', fontSize: 11.5),
        for (final g in list) ...[
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              border: Border.all(color: AppColors.ink, width: 3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(g.title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                ),
                const SizedBox(width: 8),
                DeleteButton(onTap: () => c.removeGoal(tier, g), label: '목표 지우기', size: 32, iconSize: 10),
              ],
            ),
          ),
        ],
        if (list.length < cap) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    border: Border.all(color: AppColors.ink, width: 3),
                  ),
                  child: Semantics(
                    label: '$name 입력',
                    child: TextField(
                      controller: c.goalInputs[tier],
                      cursorColor: AppColors.brownText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brownText),
                      decoration: pixelInputDecoration(weekly ? '예: 주 3회 러닝' : '예: 책 2권 완독'),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => c.addGoal(tier),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 58,
                child: PixelButton(
                  label: '추가',
                  onPressed: () => c.addGoal(tier),
                  color: AppColors.yellowButton,
                  shadowColor: AppColors.yellowShadow,
                  textColor: AppColors.brownText,
                  height: 44,
                  depth: 3,
                  fontSize: 12,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "골드로 살 수 있는 것은?" 펼침 목록.
class _ShopPreview extends StatelessWidget {
  const _ShopPreview();

  static String _hint(int price) {
    if (price <= Economy.weeklyGoalGold) return '주간 목표 1개면 ${Economy.weeklyGoalGold ~/ price}개!';
    if (price <= Economy.monthlyGoalGold) return '월간 목표 1개면 ${Economy.monthlyGoalGold ~/ price}개!';
    return '꾸준히 모으면 한 번에 크게!';
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final it in Catalog.items)
        (it.asset, it.name, '+${it.exp} EXP · 골드당 효율 ${it.goldEfficiency.toStringAsFixed(2)}', it.price),
      (
        Catalog.seongsilBall.asset,
        Catalog.seongsilBall.name,
        '탐색에서 만난 몬스터를 잡는 볼',
        Economy.seongsilBallPrice,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.ink, width: 3),
      ),
      child: Column(
        children: [
          for (final (asset, name, desc, price) in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
              ),
              child: Row(
                children: [
                  PixelImage(asset, height: 22),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                        const SizedBox(height: 2),
                        Text('$desc · ${_hint(price)}',
                            style: const TextStyle(fontSize: 9.5, color: AppColors.brownMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text('${price}G',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldDeep)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
