import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pixel_widgets.dart';
import 'popup_card.dart';

/// 설명 창의 한 항목 (소제목, 내용).
typedef InfoItem = (String, String);

/// 화면 가운데에 설명 창을 띄운다 (제목 리본 + 항목들 + 확인). 바깥을 눌러도 닫힌다.
Future<void> showInfoPopup(BuildContext context, {required String title, required List<InfoItem> items}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '$title 닫기',
    barrierColor: AppColors.black.withValues(alpha: 0),
    pageBuilder: (ctx, _, __) => _InfoPopup(title: title, items: items),
  );
}

class _InfoPopup extends StatelessWidget {
  const _InfoPopup({required this.title, required this.items});
  final String title;
  final List<InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: PopupCard(
          title: title,
          ribbonColor: AppColors.purple,
          ribbonText: AppColors.white,
          maxWidth: 300,
          children: [
            GestureDetector(
              onTap: () {}, // 카드 안을 눌러도 닫히지 않게
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (head, body) in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(head,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brownText)),
                          const SizedBox(height: 2),
                          Text(body, style: const TextStyle(fontSize: 11, height: 1.6, color: AppColors.brownMuted)),
                        ],
                      ),
                    ),
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

/// 처음 보는 말 옆에 붙이는 ? 버튼. 누르면 [showInfoPopup]으로 설명을 띄운다.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.title, required this.items});
  final String title;
  final List<InfoItem> items;

  @override
  Widget build(BuildContext context) {
    void open() => showInfoPopup(context, title: title, items: items);
    return Semantics(
      button: true,
      label: '$title 설명',
      excludeSemantics: true,
      onTap: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purple,
              border: Border.all(color: AppColors.purpleSoft, width: 2),
            ),
            child: const Text('?',
                style: TextStyle(fontSize: 10, height: 1, fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}
