import 'dart:math' as math;

import '../models/pose_models.dart';

class PoseMatchResult {
  const PoseMatchResult({required this.score, required this.suggestion});

  final double score;
  final String suggestion;
}

class PoseComparator {
  const PoseComparator._();

  static PoseMatchResult compare(PoseKeypoints user, PoseKeypoints template) {
    final u = _normalize(user);
    final t = _normalize(template);
    final scores = <String, double>{
      '左臂': _limb(
        u.leftShoulder,
        u.leftElbow,
        u.leftWrist,
        t.leftShoulder,
        t.leftElbow,
        t.leftWrist,
        u.leftHip,
        t.leftHip,
      ),
      '右臂': _limb(
        u.rightShoulder,
        u.rightElbow,
        u.rightWrist,
        t.rightShoulder,
        t.rightElbow,
        t.rightWrist,
        u.rightHip,
        t.rightHip,
      ),
      '躯干': _angleScore(
        _angle(u.leftShoulder, u.shoulderMid, u.hipMid),
        _angle(t.leftShoulder, t.shoulderMid, t.hipMid),
        20,
      ),
    };
    final score =
        scores['左臂']! * .45 + scores['右臂']! * .45 + scores['躯干']! * .1;
    final worst = scores.entries.reduce((a, b) => a.value < b.value ? a : b);
    final suggestion =
        worst.value >= 85
            ? '姿势很棒，保持住！'
            : worst.value >= 70
            ? '${worst.key}再调整一下就更好了'
            : worst.value >= 50
            ? '${worst.key}需要调整一下'
            : '${worst.key}差得比较多，再试试';
    return PoseMatchResult(score: score.clamp(0, 100), suggestion: suggestion);
  }

  static PoseKeypoints _normalize(PoseKeypoints pose) {
    final mid = pose.shoulderMid;
    final scale = pose.shoulderWidth > 0 ? 1 / pose.shoulderWidth : 1.0;
    PosePoint norm(PosePoint p) => PosePoint(
      (p.x - mid.x) * scale,
      (p.y - mid.y) * scale,
      z: (p.z - mid.z) * scale,
      visibility: p.visibility,
    );
    final points = pose.allPoints.map(norm).toList();
    return PoseKeypoints(
      nose: points[0],
      leftShoulder: points[1],
      rightShoulder: points[2],
      leftElbow: points[3],
      rightElbow: points[4],
      leftWrist: points[5],
      rightWrist: points[6],
      leftHip: points[7],
      rightHip: points[8],
      leftKnee: points[9],
      rightKnee: points[10],
      leftAnkle: points[11],
      rightAnkle: points[12],
      bounds: pose.bounds,
    );
  }

  static double _limb(
    PosePoint shoulder,
    PosePoint elbow,
    PosePoint wrist,
    PosePoint tShoulder,
    PosePoint tElbow,
    PosePoint tWrist,
    PosePoint hip,
    PosePoint tHip,
  ) {
    final elbowScore = _angleScore(
      _angle(shoulder, elbow, wrist),
      _angle(tShoulder, tElbow, tWrist),
      45,
    );
    final shoulderScore = _angleScore(
      _angle(hip, shoulder, elbow),
      _angle(tHip, tShoulder, tElbow),
      60,
    );
    return elbowScore * .4 + shoulderScore * .6;
  }

  static double _angle(PosePoint a, PosePoint b, PosePoint c) {
    final v1x = a.x - b.x;
    final v1y = a.y - b.y;
    final v2x = c.x - b.x;
    final v2y = c.y - b.y;
    final denominator =
        math.sqrt(v1x * v1x + v1y * v1y) * math.sqrt(v2x * v2x + v2y * v2y);
    if (denominator == 0) return 0;
    final cosine = ((v1x * v2x + v1y * v2y) / denominator).clamp(-1, 1);
    return math.acos(cosine) * 180 / math.pi;
  }

  static double _angleScore(double a, double b, double maxDiff) =>
      ((1 - (a - b).abs() / maxDiff).clamp(0, 1)) * 100;
}
