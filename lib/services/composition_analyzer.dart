import 'dart:math' as math;

import 'package:camera/camera.dart';

import '../models/pose_models.dart';

/// A deliberately small, on-device first pass at composition.
///
/// It does not try to name the scene. Instead it looks for two robust signals
/// that are useful while a camera preview is moving: approximate symmetry and
/// a noticeably calmer side of the frame. More ambitious scene recognition can
/// be layered on top later without changing the overlay interaction model.
class CompositionAnalyzer {
  const CompositionAnalyzer();

  CompositionLayout analyze({
    required CameraImage image,
    required PoseTemplate template,
  }) {
    if (image.planes.isEmpty || image.width < 2 || image.height < 2) {
      return CompositionLayout.defaultFor(template);
    }

    final plane = image.planes.first;
    final bytes = plane.bytes;
    final rowStride = plane.bytesPerRow;
    final bytesPerPixel = plane.bytesPerPixel ?? 1;
    if (bytes.isEmpty || rowStride <= 0) {
      return CompositionLayout.defaultFor(template);
    }

    // Sample just 48 × 72 luminance values. NV21's first plane is luma, and
    // for BGRA this still gives us a stable enough brightness proxy at the
    // small sample rate used here.
    const columns = 48;
    const rows = 72;
    final values = List<int>.filled(columns * rows, 0);
    for (var y = 0; y < rows; y++) {
      final sourceY = ((y + .5) * image.height / rows).floor().clamp(
        0,
        image.height - 1,
      );
      for (var x = 0; x < columns; x++) {
        final sourceX = ((x + .5) * image.width / columns).floor().clamp(
          0,
          image.width - 1,
        );
        final index = sourceY * rowStride + sourceX * bytesPerPixel;
        if (index >= bytes.length) {
          values[y * columns + x] = 0;
        } else if (bytesPerPixel >= 3 && index + 2 < bytes.length) {
          values[y * columns + x] =
              ((bytes[index] + bytes[index + 1] + bytes[index + 2]) / 3)
                  .round();
        } else {
          values[y * columns + x] = bytes[index];
        }
      }
    }

    var symmetryDifference = 0.0;
    var symmetrySamples = 0;
    var leftEnergy = 0.0;
    var rightEnergy = 0.0;
    for (var y = 1; y < rows - 1; y++) {
      for (var x = 1; x < columns - 1; x++) {
        final value = values[y * columns + x];
        final mirrored = values[y * columns + (columns - 1 - x)];
        symmetryDifference += (value - mirrored).abs();
        symmetrySamples++;

        final horizontal = (value - values[y * columns + x - 1]).abs();
        final vertical = (value - values[(y - 1) * columns + x]).abs();
        final energy = horizontal + vertical;
        if (x < columns / 2) {
          leftEnergy += energy;
        } else {
          rightEnergy += energy;
        }
      }
    }

    final averageDifference = symmetryDifference / math.max(1, symmetrySamples);
    final symmetry = (1 - averageDifference / 80).clamp(0.0, 1.0);
    final energyGap =
        (leftEnergy - rightEnergy).abs() /
        math.max(1.0, leftEnergy + rightEnergy);

    // Symmetry needs to be strong before we suggest a centred portrait: a
    // false symmetry recommendation is more distracting than a neutral one.
    if (symmetry > .72 && energyGap < .12) {
      return CompositionLayout(
        style: CompositionStyle.centeredSymmetry,
        centerX: .5,
        centerY: .51,
        heightRatio: template.heightRatio * .9,
        label: '对称居中',
      );
    }

    // A substantially quieter side is useful as negative space. Put the
    // subject on the opposite third so the quiet area remains visible.
    if (energyGap > .18) {
      final leftIsQuieter = leftEnergy < rightEnergy;
      return CompositionLayout(
        style:
            leftIsQuieter
                ? CompositionStyle.rightThird
                : CompositionStyle.leftThird,
        centerX: leftIsQuieter ? .67 : .33,
        centerY: .52,
        heightRatio: template.heightRatio * .93,
        label: '三分留白',
      );
    }

    return CompositionLayout.defaultFor(template);
  }
}
