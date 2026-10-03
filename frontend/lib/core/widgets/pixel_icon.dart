import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 16×16 격자 위의 SVG path 한 겹 (예: 'M7 1h2v2h1…z').
class PixelLayer {
  const PixelLayer(this.path, this.color);
  final String path;
  final Color color;
}

/// 시안의 픽셀 SVG 아이콘을 그대로 그린다.
///
/// [outline] > 0 이면 시안의 `drop-shadow` 4방향 외곽선처럼 [outlineColor] 테두리를 두른다.
/// [strokeWidth]가 있으면 채우기 대신 선으로 그린다 (체크 ✓, 지우기 ✕).
class PixelIcon extends StatelessWidget {
  const PixelIcon({
    super.key,
    required this.layers,
    required this.size,
    this.outline = 0,
    this.outlineColor = AppColors.ink,
    this.strokeWidth,
    this.height,
    this.viewBox = 16,
  });

  final List<PixelLayer> layers;
  final double size;

  /// 세로 크기 (없으면 [size]와 같은 정사각형).
  final double? height;

  /// path 좌표계의 가로 칸 수 (대부분 16).
  final double viewBox;
  final double outline;
  final Color outlineColor;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, height ?? size),
      painter: _PixelIconPainter(layers, outline, outlineColor, strokeWidth, viewBox),
    );
  }
}

class _PixelIconPainter extends CustomPainter {
  _PixelIconPainter(this.layers, this.outline, this.outlineColor, this.strokeWidth, this.viewBox);
  final List<PixelLayer> layers;
  final double viewBox;
  final double outline;
  final Color outlineColor;
  final double? strokeWidth;

  static final Map<String, Path> _cache = {};
  static Path _parse(String d) => _cache.putIfAbsent(d, () => parseSvgPath(d));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox;
    final stroke = strokeWidth;
    Paint paintFor(Color c) {
      final p = Paint()
        ..color = c
        ..isAntiAlias = false;
      if (stroke != null) {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke;
      }
      return p;
    }

    void drawAll(Offset shift, Color? only) {
      canvas.save();
      canvas.translate(shift.dx, shift.dy);
      canvas.scale(scale);
      for (final l in layers) {
        canvas.drawPath(_parse(l.path), paintFor(only ?? l.color));
      }
      canvas.restore();
    }

    if (outline > 0) {
      for (final dx in [-outline, 0.0, outline]) {
        for (final dy in [-outline, 0.0, outline]) {
          if (dx == 0 && dy == 0) continue;
          drawAll(Offset(dx, dy), outlineColor);
        }
      }
    }
    drawAll(Offset.zero, null);
  }

  @override
  bool shouldRepaint(covariant _PixelIconPainter old) =>
      old.layers != layers || old.outline != outline || old.strokeWidth != strokeWidth;
}

/// 시안에서 쓰는 SVG path 명령(M L H V Z, 대소문자)만 해석한다.
Path parseSvgPath(String d) {
  final tokens = RegExp(r'[MmLlHhVvZz]|-?\d*\.?\d+').allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  var cmd = 'M';
  var i = 0;
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final t = tokens[i];
    if (RegExp(r'^[A-Za-z]$').hasMatch(t)) {
      cmd = t;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        x = sx;
        y = sy;
        continue;
      }
    }
    switch (cmd) {
      case 'M':
      case 'm':
        final nx = next(), ny = next();
        x = cmd == 'm' ? x + nx : nx;
        y = cmd == 'm' ? y + ny : ny;
        sx = x;
        sy = y;
        path.moveTo(x, y);
        cmd = cmd == 'm' ? 'l' : 'L'; // 이어지는 좌표는 선
      case 'L':
      case 'l':
        final nx = next(), ny = next();
        x = cmd == 'l' ? x + nx : nx;
        y = cmd == 'l' ? y + ny : ny;
        path.lineTo(x, y);
      case 'H':
      case 'h':
        final nx = next();
        x = cmd == 'h' ? x + nx : nx;
        path.lineTo(x, y);
      case 'V':
      case 'v':
        final ny = next();
        y = cmd == 'v' ? y + ny : ny;
        path.lineTo(x, y);
      default:
        i++;
    }
  }
  return path;
}
