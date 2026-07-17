import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 68, 23, 22),
          child: Column(
            children: [
              const Icon(Icons.adjust_rounded, size: 38, color: AppColors.blue),
              const SizedBox(height: 40),
              const Text(
                'AI 相机',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '帮拍别人的人，拍出好照片',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
              ),
              const SizedBox(height: 34),
              const _FeatureRow(
                icon: Icons.auto_awesome,
                title: '智能场景识别',
                subtitle: '自动识别拍摄场景，推荐最佳姿势',
              ),
              const SizedBox(height: 18),
              const _FeatureRow(
                icon: Icons.social_distance_outlined,
                title: '双向角度引导',
                subtitle: '提示你和被拍者各自调整',
              ),
              const SizedBox(height: 18),
              const _FeatureRow(
                icon: Icons.dynamic_feed_outlined,
                title: 'AI 智能选片',
                subtitle: '从几张中秒选最好的',
              ),
              const Spacer(),
              FilledButton(onPressed: onComplete, child: const Text('开始使用')),
              const SizedBox(height: 10),
              const Text(
                '拍5张就能出片',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.blue, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
