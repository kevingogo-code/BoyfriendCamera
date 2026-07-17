import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class PhotoDetailScreen extends StatelessWidget {
  const PhotoDetailScreen({super.key, required this.photo, this.shot});

  final File photo;
  final CapturedShot? shot;

  @override
  Widget build(BuildContext context) {
    final score = shot?.score ?? 92;
    return Scaffold(
      appBar: AppBar(
        title: const Text('照片详情'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: .68,
                    child: Image.file(photo, fit: BoxFit.cover),
                  ),
                ),
                const Positioned(
                  right: 12,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xD9000000),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        '✓ 推荐',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 7),
                  child: Text(
                    ' 分',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Metric(label: '姿势', value: '自然'),
                _Metric(label: '光线', value: '均匀'),
                _Metric(label: '构图', value: '稳定'),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shot?.reason ?? '角度和光线都很棒，是一张出片',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Action(label: '编辑'),
                _Action(label: '分享'),
                _Action(label: '保存到相册'),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              '更多推荐',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 3),
        Text('✓  $value', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
