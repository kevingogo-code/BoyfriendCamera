import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import 'smart_selection_screen.dart';

class CaptureCompleteScreen extends StatelessWidget {
  const CaptureCompleteScreen({
    super.key,
    required this.shots,
    required this.onContinue,
  });

  final List<CapturedShot> shots;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final sorted = [...shots]..sort((a, b) => b.score.compareTo(a.score));
    final recommended = sorted.length.clamp(0, 3);
    final backup = sorted.length > 3 ? (sorted.length - 3).clamp(0, 1) : 0;
    final discard = (sorted.length - recommended - backup).clamp(0, 99);
    return Scaffold(
      appBar: AppBar(title: const Text('拍摄完成')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 110, 15, 24),
          child: Column(
            children: [
              const Text(
                '拍摄完成',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '共拍摄 ${shots.length} 张照片',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI 分析完成',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    _ResultRow(label: '推荐', count: recommended),
                    _ResultRow(
                      label: '备选',
                      count: backup,
                      dot: AppColors.orange,
                    ),
                    _ResultRow(label: '可删', count: discard, showDot: false),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    for (var index = 0; index < shots.length; index++) ...[
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.fill,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                index == 3
                                    ? Border.all(
                                      color: AppColors.orange,
                                      width: 2,
                                    )
                                    : null,
                            image: DecorationImage(
                              image: FileImage(shots[index].file),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (index != shots.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SmartSelectionScreen(shots: shots),
                      ),
                    ),
                child: const Text('查看推荐'),
              ),
              TextButton(
                onPressed: onContinue,
                child: const Text(
                  '继续拍摄  ›',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              const Text(
                '照片已自动保存到相册',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.count,
    this.dot = AppColors.blue,
    this.showDot = true,
  });

  final String label;
  final int count;
  final Color dot;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child:
                showDot
                    ? CircleAvatar(radius: 3.5, backgroundColor: dot)
                    : const SizedBox(),
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text('$count 张', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
