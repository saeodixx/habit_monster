import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pixel_widgets.dart';

/// 아직 만들지 않은 탭의 자리 표시. 무엇을 만들지 목록으로 보여준다.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.todo});
  final String title;
  final List<String> todo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brownText)),
              const SizedBox(height: 6),
              const Text('디자인: docs/design/habit-monster-prototype.html',
                  style: TextStyle(fontSize: 10, color: AppColors.brownMuted)),
              const SizedBox(height: 12),
              for (final t in todo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('□ $t', style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.brownText)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
