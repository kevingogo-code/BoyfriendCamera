import 'dart:typed_data';

/// Minimal plane description used to make CameraX YUV conversion testable
/// without constructing platform camera objects.
class YuvPlaneData {
  const YuvPlaneData({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

/// Converts Android YUV_420_888 planes to the packed NV21 layout accepted by
/// ML Kit's InputImage.fromBytes API.
///
/// The conversion respects both row padding and chroma pixel stride, which
/// vary between Android camera vendors.
Uint8List? convertYuv420ToNv21({
  required int width,
  required int height,
  required YuvPlaneData yPlane,
  required YuvPlaneData uPlane,
  required YuvPlaneData vPlane,
}) {
  if (width <= 0 || height <= 0 || width.isOdd || height.isOdd) return null;
  if (yPlane.bytesPerRow <= 0 ||
      yPlane.bytesPerPixel <= 0 ||
      uPlane.bytesPerRow <= 0 ||
      uPlane.bytesPerPixel <= 0 ||
      vPlane.bytesPerRow <= 0 ||
      vPlane.bytesPerPixel <= 0) {
    return null;
  }

  final ySize = width * height;
  final output = Uint8List(ySize + ySize ~/ 2);

  for (var row = 0; row < height; row++) {
    final sourceRow = row * yPlane.bytesPerRow;
    final targetRow = row * width;
    if (yPlane.bytesPerPixel == 1 && sourceRow + width <= yPlane.bytes.length) {
      output.setRange(targetRow, targetRow + width, yPlane.bytes, sourceRow);
      continue;
    }
    for (var column = 0; column < width; column++) {
      final source = sourceRow + column * yPlane.bytesPerPixel;
      if (source >= yPlane.bytes.length) return null;
      output[targetRow + column] = yPlane.bytes[source];
    }
  }

  var target = ySize;
  final chromaWidth = width ~/ 2;
  final chromaHeight = height ~/ 2;
  for (var row = 0; row < chromaHeight; row++) {
    final uRow = row * uPlane.bytesPerRow;
    final vRow = row * vPlane.bytesPerRow;
    for (var column = 0; column < chromaWidth; column++) {
      final uIndex = uRow + column * uPlane.bytesPerPixel;
      final vIndex = vRow + column * vPlane.bytesPerPixel;
      if (uIndex >= uPlane.bytes.length || vIndex >= vPlane.bytes.length) {
        return null;
      }
      output[target++] = vPlane.bytes[vIndex];
      output[target++] = uPlane.bytes[uIndex];
    }
  }
  return output;
}
