import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/pose_models.dart';
import 'pose_comparator.dart';
import 'yuv420_converter.dart';

class PoseFrameResult {
  const PoseFrameResult({required this.keypoints, required this.match});

  final PoseKeypoints keypoints;
  final PoseMatchResult match;
}

class PoseAnalyzer {
  PoseAnalyzer()
    : _detector = PoseDetector(
        options: PoseDetectorOptions(
          model: PoseDetectionModel.base,
          mode: PoseDetectionMode.stream,
        ),
      );

  final PoseDetector _detector;

  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<PoseFrameResult?> analyze({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    required PoseTemplate template,
  }) async {
    final converted = _toInputImage(image, camera, deviceOrientation);
    if (converted == null) return null;
    final poses = await _detector.processImage(converted.image);
    if (poses.isEmpty) return null;
    final keypoints = _toKeypoints(poses.first, image, converted.rotation);
    if (keypoints == null) return null;
    return PoseFrameResult(
      keypoints: keypoints,
      match: PoseComparator.compare(keypoints, template.keypoints),
    );
  }

  _ConvertedImage? _toInputImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else if (Platform.isAndroid) {
      var compensation = _orientations[deviceOrientation];
      if (compensation == null) return null;
      compensation =
          camera.lensDirection == CameraLensDirection.front
              ? (camera.sensorOrientation + compensation) % 360
              : (camera.sensorOrientation - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    late Uint8List bytes;
    late InputImageFormat format;
    late int bytesPerRow;
    if (Platform.isAndroid) {
      if (image.format.group == ImageFormatGroup.nv21 &&
          image.planes.length == 1) {
        final plane = image.planes.first;
        bytes = plane.bytes;
        bytesPerRow = plane.bytesPerRow;
      } else if (image.format.group == ImageFormatGroup.yuv420 &&
          image.planes.length == 3) {
        final y = image.planes[0];
        final u = image.planes[1];
        final v = image.planes[2];
        final converted = convertYuv420ToNv21(
          width: image.width,
          height: image.height,
          yPlane: YuvPlaneData(
            bytes: y.bytes,
            bytesPerRow: y.bytesPerRow,
            bytesPerPixel: y.bytesPerPixel ?? 1,
          ),
          uPlane: YuvPlaneData(
            bytes: u.bytes,
            bytesPerRow: u.bytesPerRow,
            bytesPerPixel: u.bytesPerPixel ?? 1,
          ),
          vPlane: YuvPlaneData(
            bytes: v.bytes,
            bytesPerRow: v.bytesPerRow,
            bytesPerPixel: v.bytesPerPixel ?? 1,
          ),
        );
        if (converted == null) return null;
        bytes = converted;
        bytesPerRow = image.width;
      } else {
        return null;
      }
      format = InputImageFormat.nv21;
    } else if (Platform.isIOS &&
        image.format.group == ImageFormatGroup.bgra8888 &&
        image.planes.length == 1) {
      final plane = image.planes.first;
      bytes = plane.bytes;
      bytesPerRow = plane.bytesPerRow;
      format = InputImageFormat.bgra8888;
    } else {
      return null;
    }

    final input = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
    return _ConvertedImage(input, rotation);
  }

  PoseKeypoints? _toKeypoints(
    Pose pose,
    CameraImage image,
    InputImageRotation rotation,
  ) {
    PoseLandmark? landmark(PoseLandmarkType type) => pose.landmarks[type];
    final core = [
      landmark(PoseLandmarkType.leftShoulder),
      landmark(PoseLandmarkType.rightShoulder),
      landmark(PoseLandmarkType.leftHip),
      landmark(PoseLandmarkType.rightHip),
    ];
    if (core.any((point) => point == null || point.likelihood < .3)) {
      return null;
    }

    final rotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final width = (rotated ? image.height : image.width).toDouble();
    final height = (rotated ? image.width : image.height).toDouble();

    PosePoint point(PoseLandmarkType type) {
      final value = landmark(type);
      if (value == null) return const PosePoint(0, 0, visibility: 0);
      return PosePoint(
        (value.x / width).clamp(0, 1),
        (value.y / height).clamp(0, 1),
        z: value.z / width,
        visibility: value.likelihood,
      );
    }

    final points = <PosePoint>[
      point(PoseLandmarkType.nose),
      point(PoseLandmarkType.leftShoulder),
      point(PoseLandmarkType.rightShoulder),
      point(PoseLandmarkType.leftElbow),
      point(PoseLandmarkType.rightElbow),
      point(PoseLandmarkType.leftWrist),
      point(PoseLandmarkType.rightWrist),
      point(PoseLandmarkType.leftHip),
      point(PoseLandmarkType.rightHip),
      point(PoseLandmarkType.leftKnee),
      point(PoseLandmarkType.rightKnee),
      point(PoseLandmarkType.leftAnkle),
      point(PoseLandmarkType.rightAnkle),
    ];
    final visible = points.where((point) => point.visibility > .2).toList();
    final minX = visible.map((point) => point.x).reduce(math.min);
    final maxX = visible.map((point) => point.x).reduce(math.max);
    final minY = visible.map((point) => point.y).reduce(math.min);
    final maxY = visible.map((point) => point.y).reduce(math.max);
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
      bounds: PoseBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY),
    );
  }

  Future<void> dispose() => _detector.close();
}

class _ConvertedImage {
  const _ConvertedImage(this.image, this.rotation);

  final InputImage image;
  final InputImageRotation rotation;
}
