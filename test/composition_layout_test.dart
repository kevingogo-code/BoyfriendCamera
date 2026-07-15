import 'package:boyfriend_camera/models/pose_models.dart';
import 'package:boyfriend_camera/services/composition_analyzer.dart';
import 'package:boyfriend_camera/services/scene_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pose = poseTemplates.first;

  test('姿势轮廓等比填充构图安全区域', () {
    const layout = CompositionLayout(
      style: CompositionStyle.leadingLines,
      centerX: .5,
      centerY: .58,
      targetWidthRatio: .32,
      subjectHeightRatio: .82,
      label: '引导线构图',
    );

    final height = layout.heightFor(pose);

    expect(height, closeTo(.32 / pose.aspectRatio, .001));
    expect(height * pose.aspectRatio, lessThanOrEqualTo(.32));
  });

  test('安全边距会限制过大的自动轮廓', () {
    const layout = CompositionLayout(
      style: CompositionStyle.leftThird,
      centerX: .33,
      centerY: .52,
      targetWidthRatio: .9,
      subjectHeightRatio: .9,
      label: '三分留白',
    );

    final height = layout.heightFor(pose);

    expect(height, lessThanOrEqualTo(.9));
    expect(
      height * pose.aspectRatio / 2 + layout.centerX,
      lessThanOrEqualTo(.96),
    );
  });

  test('楼宇环境人像明显小于热闹街景人物', () {
    const analyzer = CompositionAnalyzer();
    final fallback = CompositionLayout.defaultFor(pose);
    final building = analyzer.refineForScene(
      const SceneClassification(label: 'building', confidence: 1),
      pose,
      fallback,
    );
    final busy = analyzer.refineForScene(
      const SceneClassification(label: 'busy', confidence: 1),
      pose,
      fallback,
    );

    expect(building.heightFor(pose), closeTo(.58, .001));
    expect(busy.heightFor(pose), closeTo(.84, .001));
    expect(busy.heightFor(pose) - building.heightFor(pose), greaterThan(.2));
  });

  test('场景大小不会覆盖强几何构图的位置', () {
    const analyzer = CompositionAnalyzer();
    const geometry = CompositionLayout(
      style: CompositionStyle.centeredSymmetry,
      centerX: .5,
      centerY: .51,
      targetWidthRatio: .56,
      subjectHeightRatio: .8,
      label: '对称居中',
    );
    final result = analyzer.refineForScene(
      const SceneClassification(label: 'street', confidence: 1),
      pose,
      geometry,
    );

    expect(result.style, CompositionStyle.centeredSymmetry);
    expect(result.centerX, .5);
    expect(result.centerY, .51);
    expect(result.heightFor(pose), closeTo(.67, .001));
  });

  test('同位置同构图下四个百分点的尺寸变化仍会更新', () {
    const first = CompositionLayout(
      style: CompositionStyle.rightThird,
      centerX: .67,
      centerY: .53,
      targetWidthRatio: .46,
      subjectHeightRatio: .58,
      label: '楼宇环境人像',
    );
    const second = CompositionLayout(
      style: CompositionStyle.rightThird,
      centerX: .67,
      centerY: .53,
      targetWidthRatio: .46,
      subjectHeightRatio: .62,
      label: '绿意留白构图',
    );

    expect(first.isCloseTo(second, pose), isFalse);
  });
}
