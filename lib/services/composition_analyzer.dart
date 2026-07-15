import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../models/pose_models.dart';

/// Low-frequency, on-device scene geometry analysis for the camera overlay.
///
/// This intentionally uses only a small luma sample instead of a cloud model:
/// it can recognise reliable visual structure (symmetry, converging diagonal
/// lines and calm negative space) without adding a network or a heavy model to
/// the live camera path.
class CompositionAnalyzer {
  const CompositionAnalyzer();

  static const _columns = 54;
  static const _rows = 96;

  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CompositionLayout analyze({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    required PoseTemplate template,
  }) {
    if (image.planes.isEmpty || image.width < 2 || image.height < 2) {
      return CompositionLayout.defaultFor(template);
    }

    final rotation = _rotationFor(camera, deviceOrientation);
    final values = _samplePortraitLuma(image, rotation);
    if (values == null) return CompositionLayout.defaultFor(template);
    final scene = _inspect(values);

    // A strong mirror pattern is the safest signal for doors, corridors and
    // front-facing architecture. It takes precedence over any incidental line.
    if (scene.symmetry > .72 && scene.energyGap < .12) {
      final structuralConfidence = ((scene.symmetry - .72) / .28).clamp(
        0.0,
        1.0,
      );
      return CompositionLayout(
        style: CompositionStyle.centeredSymmetry,
        centerX: .5,
        centerY: .51,
        targetWidthRatio: .46 + structuralConfidence * .12,
        targetHeightRatio: .68 + structuralConfidence * .14,
        label: '对称居中',
      );
    }

    // A pair of diagonals converging inside the frame is typical of paths,
    // railings and stairs. Position the subject just below the convergence so
    // the lines still lead the eye toward them.
    final vanishingPoint = scene.vanishingPoint;
    if (vanishingPoint != null && scene.lineConfidence > .18) {
      final centerY = (vanishingPoint.dy / _rows + .2).clamp(.46, .62);
      final safeHeight = _safeHeightFor(centerY);
      final corridorWidth = scene.corridorWidth ?? .46;
      return CompositionLayout(
        style: CompositionStyle.leadingLines,
        centerX: (vanishingPoint.dx / _columns).clamp(.33, .67),
        centerY: centerY,
        targetWidthRatio: (corridorWidth * .76).clamp(.32, .62),
        targetHeightRatio: safeHeight,
        label: '引导线构图',
      );
    }

    // A substantially quieter side is useful as negative space. Keep it
    // visible by putting the silhouette on the opposite third.
    if (scene.energyGap > .18) {
      final leftIsQuieter = scene.leftEnergy < scene.rightEnergy;
      final spaceStrength = ((scene.energyGap - .18) / .45).clamp(0.0, 1.0);
      return CompositionLayout(
        style:
            leftIsQuieter
                ? CompositionStyle.rightThird
                : CompositionStyle.leftThird,
        centerX: leftIsQuieter ? .67 : .33,
        centerY: .52,
        targetWidthRatio: .42 + spaceStrength * .14,
        targetHeightRatio: .68 + spaceStrength * .1,
        label: '三分留白',
      );
    }

    return CompositionLayout.defaultFor(template);
  }

  double _safeHeightFor(double centerY) {
    const topMargin = .06;
    const bottomMargin = .05;
    final roomAbove = 2 * (centerY - topMargin);
    final roomBelow = 2 * (1 - bottomMargin - centerY);
    return math.min(roomAbove, roomBelow).clamp(.46, .84);
  }

  int _rotationFor(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    if (Platform.isIOS) return camera.sensorOrientation;
    final compensation = _orientations[deviceOrientation] ?? 0;
    return camera.lensDirection == CameraLensDirection.front
        ? (camera.sensorOrientation + compensation) % 360
        : (camera.sensorOrientation - compensation + 360) % 360;
  }

  List<int>? _samplePortraitLuma(CameraImage image, int rotation) {
    final plane = image.planes.first;
    final bytes = plane.bytes;
    if (bytes.isEmpty || plane.bytesPerRow <= 0) return null;
    final bytesPerPixel = plane.bytesPerPixel ?? 1;
    final rotated = rotation == 90 || rotation == 270;
    final uprightWidth = rotated ? image.height : image.width;
    final uprightHeight = rotated ? image.width : image.height;
    final values = List<int>.filled(_columns * _rows, 0);

    for (var y = 0; y < _rows; y++) {
      final uprightY = ((y + .5) * uprightHeight / _rows).floor().clamp(
        0,
        uprightHeight - 1,
      );
      for (var x = 0; x < _columns; x++) {
        final uprightX = ((x + .5) * uprightWidth / _columns).floor().clamp(
          0,
          uprightWidth - 1,
        );
        final raw = _rawCoordinate(
          x: uprightX,
          y: uprightY,
          width: image.width,
          height: image.height,
          rotation: rotation,
        );
        final index =
            raw.dy.toInt() * plane.bytesPerRow + raw.dx.toInt() * bytesPerPixel;
        values[y * _columns + x] = _brightness(bytes, index, bytesPerPixel);
      }
    }
    return values;
  }

  Offset _rawCoordinate({
    required int x,
    required int y,
    required int width,
    required int height,
    required int rotation,
  }) {
    switch (rotation) {
      case 90:
        return Offset(y.toDouble(), (height - 1 - x).toDouble());
      case 180:
        return Offset((width - 1 - x).toDouble(), (height - 1 - y).toDouble());
      case 270:
        return Offset((width - 1 - y).toDouble(), x.toDouble());
      default:
        return Offset(x.toDouble(), y.toDouble());
    }
  }

  int _brightness(Uint8List bytes, int index, int bytesPerPixel) {
    if (index < 0 || index >= bytes.length) return 0;
    if (bytesPerPixel >= 3 && index + 2 < bytes.length) {
      return ((bytes[index] + bytes[index + 1] + bytes[index + 2]) / 3).round();
    }
    return bytes[index];
  }

  _SceneFeatures _inspect(List<int> values) {
    var symmetryDifference = 0.0;
    var symmetrySamples = 0;
    var leftEnergy = 0.0;
    var rightEnergy = 0.0;
    final edges = <_EdgePoint>[];

    for (var y = 1; y < _rows - 1; y++) {
      for (var x = 1; x < _columns - 1; x++) {
        final index = y * _columns + x;
        final value = values[index];
        final mirrored = values[y * _columns + (_columns - 1 - x)];
        symmetryDifference += (value - mirrored).abs();
        symmetrySamples++;

        final gradientX = values[index + 1] - values[index - 1];
        final gradientY = values[index + _columns] - values[index - _columns];
        final energy = gradientX.abs() + gradientY.abs();
        if (x < _columns / 2) {
          leftEnergy += energy;
        } else {
          rightEnergy += energy;
        }

        // Keep only diagonal, high-contrast edges. Horizontal/vertical edges
        // are valuable for symmetry, but cannot establish a vanishing point.
        if (energy > 96 &&
            gradientX.abs() > 18 &&
            gradientY.abs() > 18 &&
            (gradientX.abs() / gradientY.abs()).clamp(.0, 99) < 3 &&
            (gradientY.abs() / gradientX.abs()).clamp(.0, 99) < 3 &&
            edges.length < 720) {
          edges.add(_EdgePoint(x, y));
        }
      }
    }

    final averageDifference = symmetryDifference / math.max(1, symmetrySamples);
    final symmetry = (1 - averageDifference / 80).clamp(0.0, 1.0);
    final energyGap =
        (leftEnergy - rightEnergy).abs() /
        math.max(1.0, leftEnergy + rightEnergy);
    final line = _findVanishingPoint(edges);
    return _SceneFeatures(
      symmetry: symmetry,
      energyGap: energyGap,
      leftEnergy: leftEnergy,
      rightEnergy: rightEnergy,
      vanishingPoint: line?.point,
      lineConfidence: line?.confidence ?? 0,
      corridorWidth: line?.corridorWidth,
    );
  }

  _LineIntersection? _findVanishingPoint(List<_EdgePoint> edges) {
    if (edges.length < 36) return null;
    final diagonal = math.sqrt(_columns * _columns + _rows * _rows).ceil();
    final bins = List<int>.filled(2 * diagonal + 1, 0);
    _HoughLine? bestFalling;
    _HoughLine? bestRising;

    _HoughLine? findBest(int startDegrees, int endDegrees) {
      _HoughLine? best;
      for (var degrees = startDegrees; degrees <= endDegrees; degrees += 5) {
        bins.fillRange(0, bins.length, 0);
        final radians = degrees * math.pi / 180;
        final cosine = math.cos(radians);
        final sine = math.sin(radians);
        for (final edge in edges) {
          final radius = (edge.x * cosine + edge.y * sine).round();
          bins[radius + diagonal]++;
        }
        var votes = 0;
        var radiusIndex = 0;
        for (var index = 0; index < bins.length; index++) {
          if (bins[index] > votes) {
            votes = bins[index];
            radiusIndex = index;
          }
        }
        if (best == null || votes > best.votes) {
          best = _HoughLine(
            cosine: cosine,
            sine: sine,
            radius: radiusIndex - diagonal,
            votes: votes,
          );
        }
      }
      return best;
    }

    // The two normal-angle bands correspond to opposite diagonal directions.
    bestFalling = findBest(25, 65);
    bestRising = findBest(115, 155);
    if (bestFalling == null || bestRising == null) return null;
    if (bestFalling.votes < 12 || bestRising.votes < 12) return null;

    final determinant =
        bestFalling.cosine * bestRising.sine -
        bestRising.cosine * bestFalling.sine;
    if (determinant.abs() < .05) return null;
    final x =
        (bestFalling.radius * bestRising.sine -
            bestRising.radius * bestFalling.sine) /
        determinant;
    final y =
        (bestFalling.cosine * bestRising.radius -
            bestRising.cosine * bestFalling.radius) /
        determinant;
    if (x < _columns * .2 ||
        x > _columns * .8 ||
        y < -_rows * .15 ||
        y > _rows * .72) {
      return null;
    }
    return _LineIntersection(
      point: Offset(x, y),
      confidence: math.min(bestFalling.votes, bestRising.votes) / edges.length,
      corridorWidth: _corridorWidthAt(
        bestFalling,
        bestRising,
        y: (y + _rows * .2).clamp(0, _rows.toDouble()),
      ),
    );
  }

  double? _corridorWidthAt(
    _HoughLine first,
    _HoughLine second, {
    required double y,
  }) {
    if (first.cosine.abs() < .08 || second.cosine.abs() < .08) return null;
    final firstX = (first.radius - first.sine * y) / first.cosine;
    final secondX = (second.radius - second.sine * y) / second.cosine;
    final width = (firstX - secondX).abs() / _columns;
    return width.isFinite ? width.clamp(0.0, 1.0) : null;
  }
}

class _SceneFeatures {
  const _SceneFeatures({
    required this.symmetry,
    required this.energyGap,
    required this.leftEnergy,
    required this.rightEnergy,
    required this.vanishingPoint,
    required this.lineConfidence,
    required this.corridorWidth,
  });

  final double symmetry;
  final double energyGap;
  final double leftEnergy;
  final double rightEnergy;
  final Offset? vanishingPoint;
  final double lineConfidence;
  final double? corridorWidth;
}

class _EdgePoint {
  const _EdgePoint(this.x, this.y);

  final int x;
  final int y;
}

class _HoughLine {
  const _HoughLine({
    required this.cosine,
    required this.sine,
    required this.radius,
    required this.votes,
  });

  final double cosine;
  final double sine;
  final int radius;
  final int votes;
}

class _LineIntersection {
  const _LineIntersection({
    required this.point,
    required this.confidence,
    required this.corridorWidth,
  });

  final Offset point;
  final double confidence;
  final double? corridorWidth;
}
