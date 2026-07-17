import 'dart:io';

import 'package:flutter/material.dart';

class ScenePreset {
  const ScenePreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.poseCount,
    required this.poseNames,
  });

  final String id;
  final String name;
  final IconData icon;
  final int poseCount;
  final List<String> poseNames;
}

const scenePresets = <ScenePreset>[
  ScenePreset(
    id: 'park',
    name: '公园',
    icon: Icons.park_outlined,
    poseCount: 3,
    poseNames: ['自然站姿', '侧身回眸', '坐姿特写'],
  ),
  ScenePreset(
    id: 'street',
    name: '街拍',
    icon: Icons.location_city_outlined,
    poseCount: 5,
    poseNames: ['自然走路', '侧身回眸', '倚靠站姿'],
  ),
  ScenePreset(
    id: 'indoor',
    name: '室内',
    icon: Icons.chair_outlined,
    poseCount: 4,
    poseNames: ['自然坐姿', '桌边侧身', '窗边回眸'],
  ),
  ScenePreset(
    id: 'night',
    name: '夜景',
    icon: Icons.nightlight_outlined,
    poseCount: 3,
    poseNames: ['灯下站姿', '侧脸看灯', '街边漫步'],
  ),
  ScenePreset(
    id: 'travel',
    name: '旅行',
    icon: Icons.flight_outlined,
    poseCount: 6,
    poseNames: ['风景回望', '自然行走', '张开双臂'],
  ),
  ScenePreset(
    id: 'food',
    name: '美食',
    icon: Icons.ramen_dining_outlined,
    poseCount: 2,
    poseNames: ['桌边互动', '端起食物'],
  ),
];

enum ShotCategory { recommended, backup, discard }

class CapturedShot {
  const CapturedShot({
    required this.file,
    required this.score,
    required this.sceneName,
    required this.poseName,
    required this.capturedAt,
  });

  final File file;
  final int score;
  final String sceneName;
  final String poseName;
  final DateTime capturedAt;

  ShotCategory categoryFor(int rank, int total) {
    if (rank < 3) return ShotCategory.recommended;
    if (rank < total - 1) return ShotCategory.backup;
    return ShotCategory.discard;
  }

  String get reason {
    if (score >= 88) return '姿势自然 · 构图稳定';
    if (score >= 72) return '构图完整 · 光线均匀';
    if (score >= 55) return '对焦清晰 · 色彩还原';
    return '人物位置仍可优化';
  }
}
