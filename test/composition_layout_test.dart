import 'package:boyfriend_camera/models/pose_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pose = poseTemplates.first;

  test('姿势轮廓等比填充构图安全区域', () {
    const layout = CompositionLayout(
      style: CompositionStyle.leadingLines,
      centerX: .5,
      centerY: .58,
      targetWidthRatio: .32,
      targetHeightRatio: .82,
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
      targetHeightRatio: .9,
      label: '三分留白',
    );

    final height = layout.heightFor(pose);

    expect(height, lessThanOrEqualTo(.9));
    expect(height * pose.aspectRatio / 2 + layout.centerX, lessThanOrEqualTo(.96));
  });
}
