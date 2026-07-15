import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Runs the compact, on-device street-scene classifier exported by the
/// training pipeline. It deliberately samples one frame every few seconds;
/// pose detection remains the higher-frequency camera task.
class SceneClassifier {
  static const _modelAsset = 'assets/models/street_scene_mobilenetv3.tflite';
  static const _inputSize = 160;
  static const _labels = <String>[
    'building',
    'street',
    'storefront',
    'urban_nature',
    'busy',
  ];

  Interpreter? _interpreter;

  bool get isReady => _interpreter != null;

  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(_modelAsset);
  }

  SceneClassification? analyze(CameraImage image) {
    final interpreter = _interpreter;
    if (interpreter == null || image.planes.isEmpty) return null;

    try {
      final input = Float32List(_inputSize * _inputSize * 3);
      for (var y = 0; y < _inputSize; y++) {
        final sourceY = ((y + .5) * image.height / _inputSize).floor().clamp(
          0,
          image.height - 1,
        );
        for (var x = 0; x < _inputSize; x++) {
          final sourceX = ((x + .5) * image.width / _inputSize).floor().clamp(
            0,
            image.width - 1,
          );
          final rgb = _readRgb(image, sourceX, sourceY);
          final offset = (y * _inputSize + x) * 3;
          input[offset] = rgb.$1;
          input[offset + 1] = rgb.$2;
          input[offset + 2] = rgb.$3;
        }
      }

      final output = List<List<double>>.generate(
        1,
        (_) => List<double>.filled(_labels.length, 0),
      );
      interpreter.run(input.reshape([1, _inputSize, _inputSize, 3]), output);
      final scores = output.single;
      var bestIndex = 0;
      for (var index = 1; index < scores.length; index++) {
        if (scores[index] > scores[bestIndex]) bestIndex = index;
      }
      return SceneClassification(
        label: _labels[bestIndex],
        confidence: scores[bestIndex],
      );
    } catch (_) {
      // A vendor camera can expose an unexpected YUV layout. Fall back to the
      // existing geometry-only composition path instead of disrupting capture.
      return null;
    }
  }

  (double, double, double) _readRgb(CameraImage image, int x, int y) {
    final yPlane = image.planes.first;
    final yIndex = y * yPlane.bytesPerRow + x * (yPlane.bytesPerPixel ?? 1);
    final luminance = yIndex < yPlane.bytes.length ? yPlane.bytes[yIndex] : 0;

    int u = 128;
    int v = 128;
    if (image.planes.length >= 3) {
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final chromaX = x ~/ 2;
      final chromaY = y ~/ 2;
      final uIndex =
          chromaY * uPlane.bytesPerRow + chromaX * (uPlane.bytesPerPixel ?? 1);
      final vIndex =
          chromaY * vPlane.bytesPerRow + chromaX * (vPlane.bytesPerPixel ?? 1);
      if (uIndex < uPlane.bytes.length) u = uPlane.bytes[uIndex];
      if (vIndex < vPlane.bytes.length) v = vPlane.bytes[vIndex];
    } else {
      // Android NV21 stores a full Y plane followed by interleaved VU pairs.
      final packed = yPlane.bytes;
      final uvOffset = image.width * image.height;
      final uvIndex = uvOffset + (y ~/ 2) * yPlane.bytesPerRow + (x & ~1);
      if (uvIndex + 1 < packed.length) {
        v = packed[uvIndex];
        u = packed[uvIndex + 1];
      }
    }
    final red = (luminance + 1.402 * (v - 128)).clamp(0, 255).toDouble();
    final green =
        (luminance - .344136 * (u - 128) - .714136 * (v - 128))
            .clamp(0, 255)
            .toDouble();
    final blue = (luminance + 1.772 * (u - 128)).clamp(0, 255).toDouble();
    return (red, green, blue);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

class SceneClassification {
  const SceneClassification({required this.label, required this.confidence});

  final String label;
  final double confidence;

  String get displayName => switch (label) {
    'building' => '楼宇',
    'street' => '街道',
    'storefront' => '店铺',
    'urban_nature' => '绿意街景',
    'busy' => '热闹街景',
    _ => '街拍',
  };
}
