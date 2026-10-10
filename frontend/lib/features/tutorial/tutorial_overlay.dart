import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/pixel_widgets.dart';

/// 튜토리얼 한 장면: [targets]를 감싸는 네모만 밝게 남기고 설명 카드를 띄운다.
/// [targets]가 비어 있으면 (또는 화면에 없으면) 전체를 어둡게 하고 카드를 가운데에 둔다.
class TutorialStep {
  const TutorialStep({this.targets = const [], required this.title, required this.body});
  final List<GlobalKey> targets;
  final String title;
  final String body;
}

/// 처음 홈에 들어온 사용자에게 화면을 하나씩 짚어 주는 안내.
/// 화면 전체를 덮으므로 [MainShell]의 Scaffold 위에 올린다.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.steps, required this.onDone, this.guide});
  final List<TutorialStep> steps;

  /// 마지막 장면의 "시작하기!" 또는 "건너뛰기".
  final VoidCallback onDone;

  /// 카드 왼쪽에 세울 안내 캐릭터 (대화 상대 몬스터).
  final Widget? guide;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _i = 0;
  Rect? _hole;
  Timer? _follow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    // 가리키는 곳이 움직이거나(몬스터) 화면 크기가 바뀌어도 따라가게
    _follow = Timer.periodic(const Duration(milliseconds: 300), (_) => _measure());
  }

  @override
  void dispose() {
    _follow?.cancel();
    super.dispose();
  }

  /// 지금 장면의 대상들이 화면에서 차지하는 네모 (이 위젯 기준).
  void _measure() {
    if (!mounted) return;
    final self = context.findRenderObject();
    if (self is! RenderBox || !self.hasSize) return;
    Rect? hole;
    for (final key in widget.steps[_i].targets) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero, ancestor: self) & box.size;
      hole = hole?.expandToInclude(rect) ?? rect;
    }
    hole = hole?.inflate(6);
    if (hole != _hole) setState(() => _hole = hole);
  }

  void _next() {
    if (_i >= widget.steps.length - 1) {
      widget.onDone();
      return;
    }
    setState(() {
      _i++;
      _hole = null;
    });
    _measure();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_i];
    final last = _i == widget.steps.length - 1;
    final hole = _hole;
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, box) {
        // 대상이 위쪽에 있으면 카드를 그 아래에, 아래쪽에 있으면 그 위에
        final below = hole != null && hole.center.dy < box.maxHeight / 2;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // 뒤 화면은 누를 수 없게
                onTap: () {},
                child: CustomPaint(painter: _SpotlightPainter(hole)),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: hole == null ? 0 : (below ? hole.bottom + 14 : null),
              bottom: hole == null ? 0 : (below ? null : box.maxHeight - hole.top + 14),
              child: Center(
                heightFactor: hole == null ? null : 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _card(step, last),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _card(TutorialStep step, bool last) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.ink, width: 4),
        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(6, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.guide != null) ...[
                SizedBox(width: 48, height: 48, child: Center(child: widget.guide)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style: const TextStyle(
                            fontSize: 14, height: 1.4, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                    const SizedBox(height: 4),
                    Text(step.body, style: const TextStyle(fontSize: 11.5, height: 1.7, color: AppColors.brownMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!last)
                Semantics(
                  button: true,
                  label: '튜토리얼 건너뛰기',
                  excludeSemantics: true,
                  onTap: widget.onDone,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDone,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('건너뛰기', style: TextStyle(fontSize: 11, color: AppColors.brownMuted)),
                    ),
                  ),
                ),
              const Spacer(),
              Text('${_i + 1} / ${widget.steps.length}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.brownMuted)),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                child: PixelButton(
                  label: last ? '시작하기!' : '다음 ▶',
                  onPressed: _next,
                  height: 40,
                  depth: 4,
                  fontSize: 12.5,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 어두운 막에 네모 구멍을 뚫고 금색 테두리를 두른다.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole);
  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = AppColors.scrim;
    final h = hole;
    if (h == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(h),
      scrim,
    );
    canvas.drawRect(
      h.inflate(1.5),
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => old.hole != hole;
}
