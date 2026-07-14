import 'package:boyfriend_camera/main.dart';
import 'package:boyfriend_camera/services/photo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('没有相机时显示明确错误状态', (tester) async {
    await tester.pumpWidget(
      BoyfriendCameraApp(cameras: const [], photoRepository: PhotoRepository()),
    );
    await tester.pump();

    expect(find.text('没有检测到可用相机'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
