import 'package:flutter/material.dart';

import '../../core/constants/economy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/pixel_icon.dart';
import '../../core/widgets/pixel_widgets.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/pixel_icons.dart';
import 'onboarding_controller.dart';
import 'onboarding_parts.dart';

/// 온보딩 2단계: 습관 퀘스트 만들기.
class StepHabits extends StatelessWidget {
  const StepHabits({super.key, required this.c});
  final OnboardingController c;

  @override
  Widget build(BuildContext context) {
    final has = c.habits.isNotEmpty;
    return OnboardingFrame(
      bottom: PixelButton(
        label: has ? '모험 시작 ▶' : '퀘스트를 1개 이상 등록해 주세요',
        onPressed: has ? c.finishHabits : null,
        disabledColor: AppColors.nightLine2,
        disabledShadowColor: AppColors.ink,
        disabledTextColor: AppColors.night,
      ),
      children: [
        const StepHeader(step: 2, title: '습관 퀘스트 만들기'),
        const ProfessorTip(text: '어떤 습관을 키워보겠나? 추천을 누르면 바로 채워진다네!'),
        _QuestForm(c: c),
        if (has)
          Text('등록한 퀘스트 · ${c.habits.length}개',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.purpleSoft)),
        for (final h in c.habits) _HabitRow(habit: h, onRemove: () => c.removeHabit(h)),
        const Text('하루 성실도에는 퀘스트 최대 ${Economy.dailyHabitCap}개까지 반영돼요.',
            style: TextStyle(fontSize: 9.5, height: 1.8, color: AppColors.textMuted)),
      ],
    );
  }
}

class _QuestForm extends StatelessWidget {
  const _QuestForm({required this.c});
  final OnboardingController c;

  @override
  Widget build(BuildContext context) {
    final cat = c.draftCat;
    final measure = c.draftMeasureInfo;
    return RibbonPanel(
      title: '새 습관 퀘스트',
      children: [
        // 1. 카테고리
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NumberedLabel(badge: '1', title: '어느 길의 습관?'),
            const SizedBox(height: 7),
            Row(
              children: [
                for (var i = 0; i < c.picked.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _DraftCategoryButton(c: c, id: c.picked[i])),
                ],
              ],
            ),
          ],
        ),
        if (cat != null && measure != null) ...[
          // 2. 이름
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NumberedLabel(badge: '2', title: '어떤 습관?', hint: '추천을 누르거나 직접 적기'),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 9,
                children: [
                  for (final p in Catalog.habitPresets[cat.id] ?? const <(String, int, double)>[])
                    _Chip(
                      label: p.$1,
                      on: c.draftName.text == p.$1,
                      onColor: AppColors.butter,
                      onShadow: AppColors.yellowShadow,
                      onTap: () => c.pickPreset(p),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  border: Border.all(color: AppColors.ink, width: 3),
                ),
                child: Row(
                  children: [
                    const PixelIcon(layers: PixelIcons.pencil, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextField(
                          controller: c.draftName,
                          cursorColor: AppColors.brownText,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brownText),
                          decoration: pixelInputDecoration('직접 적어도 돼요').copyWith(labelText: null),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 3. 측정 방식
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NumberedLabel(badge: '3', title: '무엇으로 셀까?'),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 9,
                children: [
                  for (var i = 0; i < cat.measures.length; i++)
                    _Chip(
                      label: '${cat.measures[i].label} · ${cat.measures[i].isOX ? 'O/X' : cat.measures[i].unit}',
                      on: c.draftMeasure == i,
                      onColor: AppColors.skyCard,
                      onShadow: AppColors.skyCardSelShadow,
                      onTap: () => c.pickMeasure(i),
                    ),
                ],
              ),
            ],
          ),
          // 4. 하루 목표
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NumberedLabel(badge: '4', title: '하루 목표'),
              const SizedBox(height: 7),
              if (c.draftNeedsTarget) _TargetStepper(c: c, unit: measure.unit),
              if (c.draftIsOX)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    border: Border.all(color: AppColors.ink, width: 3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: const Text('O',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('했으면 O, 못 했으면 X — 챗봇이 물어볼게요',
                            style: TextStyle(fontSize: 11.5, color: AppColors.brownText)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // 5. 기간
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NumberedLabel(badge: '5', title: '기간 · 끝까지 지키면 보상 상자!'),
              const SizedBox(height: 7),
              Row(
                children: [
                  for (var i = 0; i < Catalog.periods.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _PeriodButton(c: c, index: i)),
                  ],
                ],
              ),
            ],
          ),
        ],
        PixelButton(
          label: '퀘스트 등록!',
          onPressed: c.canAddHabit ? c.addHabit : null,
          color: AppColors.yellowButton,
          shadowColor: AppColors.yellowShadow,
          textColor: AppColors.brownText,
        ),
      ],
    );
  }
}

class _DraftCategoryButton extends StatelessWidget {
  const _DraftCategoryButton({required this.c, required this.id});
  final OnboardingController c;
  final String id;

  @override
  Widget build(BuildContext context) {
    final cat = Catalog.category(id);
    final cur = c.draftCategory == id;
    return PressCard(
      onTap: () => c.pickDraftCategory(id),
      sunk: cur,
      sinkBy: 3,
      depth: 4,
      color: cur ? AppColors.butter : AppColors.parchment,
      shadowColor: AppColors.tanShadow,
      minHeight: 66,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      semanticLabel: cat.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryIcon(id, size: 28),
          const SizedBox(height: 4),
          Text(cat.short,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.brownText)),
        ],
      ),
    );
  }
}

/// 추천 / 측정 방식 칩 (그림자 3px).
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.on,
    required this.onColor,
    required this.onShadow,
    required this.onTap,
  });
  final String label;
  final bool on;
  final Color onColor;
  final Color onShadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      color: on ? onColor : AppColors.white,
      shadowColor: on ? onShadow : AppColors.chipShadow,
      depth: 3,
      minHeight: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(label,
          style: const TextStyle(fontSize: 11, height: 1.5, fontWeight: FontWeight.w700, color: AppColors.brownText)),
    );
  }
}

class _TargetStepper extends StatelessWidget {
  const _TargetStepper({required this.c, required this.unit});
  final OnboardingController c;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: PixelButton(
            label: '−',
            semanticLabel: '목표 줄이기',
            onPressed: c.decTarget,
            color: AppColors.skyCard,
            shadowColor: AppColors.skyCardShadow,
            textColor: AppColors.brownText,
            height: 48,
            depth: 4,
            fontSize: 22,
            padding: EdgeInsets.zero,
            // Galmuri에 '−' 글자가 없어서 막대로 그린다.
            child: Container(width: 14, height: 4, color: AppColors.brownText),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brownText,
              border: Border.all(color: AppColors.ink, width: 3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(formatNum(c.draftTarget),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.butter)),
                const SizedBox(width: 6),
                Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.parchment)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: PixelButton(
            label: '+',
            semanticLabel: '목표 늘리기',
            onPressed: c.incTarget,
            color: AppColors.yellowButton,
            shadowColor: AppColors.yellowShadow,
            textColor: AppColors.brownText,
            height: 48,
            depth: 4,
            fontSize: 22,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.c, required this.index});
  final OnboardingController c;
  final int index;

  static const _chestSizes = [26.0, 30.0, 34.0];

  @override
  Widget build(BuildContext context) {
    final on = c.draftPeriod == index;
    final (lid, body, band) = PixelIcons.chestColors[index];
    return PressCard(
      onTap: () => c.pickPeriod(index),
      sunk: on,
      sinkBy: 3,
      depth: 4,
      color: on ? AppColors.butter : AppColors.parchment,
      shadowColor: AppColors.tanShadow,
      minHeight: 84,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _chestSizes.last,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: PixelIcon(layers: PixelIcons.chest(lid, body, band), size: _chestSizes[index], outline: 1.5),
            ),
          ),
          const SizedBox(height: 3),
          Text(Catalog.periods[index].$1,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brownText)),
          const SizedBox(height: 3),
          Text(Catalog.periodMult(index),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldDeep)),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.onRemove});
  final Habit habit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cat = Catalog.category(habit.categoryId);
    final m = cat.measures[habit.measureIndex];
    final meta = '${cat.name} · ${m.label}${m.isOX ? '' : ' ${formatNum(habit.target)}${m.unit}'}'
        ' · ${Catalog.periods[habit.periodIndex].$1} ${Catalog.periodMult(habit.periodIndex)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        border: Border.all(color: AppColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          CategoryIcon(habit.categoryId, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                const SizedBox(height: 3),
                Text(meta, style: const TextStyle(fontSize: 9.5, color: AppColors.brownMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DeleteButton(onTap: onRemove, label: '퀘스트 삭제'),
        ],
      ),
    );
  }
}
