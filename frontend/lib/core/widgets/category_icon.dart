import 'package:flutter/material.dart';

import '../../data/pixel_icons.dart';
import 'pixel_icon.dart';

/// 카테고리 픽셀 아이콘 (검은 외곽선 포함).
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.categoryId, {super.key, this.size = 26, this.outline = 1.5});
  final String categoryId;
  final double size;
  final double outline;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(layers: PixelIcons.category[categoryId]!, size: size, outline: outline);
}
