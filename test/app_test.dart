import 'package:boyfriend_camera/main.dart';
import 'package:boyfriend_camera/models/app_models.dart';
import 'package:boyfriend_camera/screens/guided_camera_screen.dart';
import 'package:boyfriend_camera/services/photo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首页展示新版拍摄入口', (tester) async {
    await tester.pumpWidget(
      BoyfriendCameraApp(cameras: const [], photoRepository: PhotoRepository()),
    );
    await tester.pump();

    expect(find.text('AI 相机'), findsOneWidget);
    expect(find.text('开始拍摄'), findsOneWidget);
    expect(find.text('最近拍摄'), findsOneWidget);
  });

  testWidgets('没有相机时拍摄页显示明确错误状态', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedCameraScreen(
          cameras: const [],
          photoRepository: PhotoRepository(),
          scene: scenePresets.first,
          manualScene: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('没有检测到可用相机'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
