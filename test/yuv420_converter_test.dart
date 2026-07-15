import 'dart:typed_data';

import 'package:boyfriend_camera/services/yuv420_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('三平面 YUV420 按行步长和像素步长转换为 NV21', () {
    final result = convertYuv420ToNv21(
      width: 4,
      height: 2,
      yPlane: YuvPlaneData(
        bytes: Uint8List.fromList([1, 2, 3, 4, 99, 99, 5, 6, 7, 8, 99, 99]),
        bytesPerRow: 6,
        bytesPerPixel: 1,
      ),
      uPlane: YuvPlaneData(
        bytes: Uint8List.fromList([10, 99, 20, 99]),
        bytesPerRow: 4,
        bytesPerPixel: 2,
      ),
      vPlane: YuvPlaneData(
        bytes: Uint8List.fromList([30, 99, 40, 99]),
        bytesPerRow: 4,
        bytesPerPixel: 2,
      ),
    );

    expect(
      result,
      Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 30, 10, 40, 20]),
    );
  });

  test('不完整的色度平面会被安全拒绝', () {
    final result = convertYuv420ToNv21(
      width: 4,
      height: 2,
      yPlane: YuvPlaneData(
        bytes: Uint8List(8),
        bytesPerRow: 4,
        bytesPerPixel: 1,
      ),
      uPlane: YuvPlaneData(
        bytes: Uint8List(1),
        bytesPerRow: 1,
        bytesPerPixel: 1,
      ),
      vPlane: YuvPlaneData(
        bytes: Uint8List(1),
        bytesPerRow: 1,
        bytesPerPixel: 1,
      ),
    );

    expect(result, isNull);
  });
}
