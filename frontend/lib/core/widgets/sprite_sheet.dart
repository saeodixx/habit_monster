import 'dart:async';

import 'package:flutter/material.dart';

/// 격자형 스프라이트 시트에서 프레임 하나를 잘라 보여주고, [playing]이면 순서대로 넘긴다.
///
/// 예) 대림대 박사: 6열 × 6행, 프레임 208×380.
class SpriteSheetPlayer extends StatefulWidget {
  const SpriteSheetPlayer({
    super.key,
    required this.asset,
    required this.columns,
    required this.rows,
    required this.frameWidth,
    required this.frameHeight,
    required this.displayHeight,
    this.playing = true,
    this.frameDuration = const Duration(milliseconds: 110),
    this.idleFrames = const [0, 1],
    this.idleFrameDuration = const Duration(milliseconds: 440),
  });

  final String asset;
  final int columns;
  final int rows;
  final double frameWidth;
  final double frameHeight;
  final double displayHeight;

  /// true: 전체 프레임을 차례로 재생 (말하는 중). false: [idleFrames]만 천천히 반복.
  final bool playing;
  final Duration frameDuration;
  final List<int> idleFrames;
  final Duration idleFrameDuration;

  @override
  State<SpriteSheetPlayer> createState() => _SpriteSheetPlayerState();
}

class _SpriteSheetPlayerState extends State<SpriteSheetPlayer> {
  Timer? _timer;
  int _frame = 0;
  int _idleIndex = 0;

  int get _total => widget.columns * widget.rows;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant SpriteSheetPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) _restart();
  }

  void _restart() {
    _timer?.cancel();
    final period = widget.playing ? widget.frameDuration : widget.idleFrameDuration;
    _timer = Timer.periodic(period, (_) {
      if (!mounted) return;
      setState(() {
        if (widget.playing) {
          _frame = (_frame + 1) % _total;
        } else {
          _idleIndex = (_idleIndex + 1) % widget.idleFrames.length;
          _frame = widget.idleFrames[_idleIndex];
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.displayHeight / widget.frameHeight;
    final w = widget.frameWidth * scale;
    final h = widget.displayHeight;
    final col = _frame % widget.columns;
    final row = _frame ~/ widget.columns;
    return SizedBox(
      width: w,
      height: h,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform.translate(
            offset: Offset(-col * w, -row * h),
            child: Image.asset(
              widget.asset,
              width: w * widget.columns,
              height: h * widget.rows,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
            ),
          ),
        ),
      ),
    );
  }
}
