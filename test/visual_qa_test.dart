import 'dart:io';

import 'package:boyfriend_camera/models/app_models.dart';
import 'package:boyfriend_camera/screens/app_shell.dart';
import 'package:boyfriend_camera/screens/capture_complete_screen.dart';
import 'package:boyfriend_camera/screens/guided_camera_screen.dart';
import 'package:boyfriend_camera/screens/onboarding_screen.dart';
import 'package:boyfriend_camera/screens/photo_detail_screen.dart';
import 'package:boyfriend_camera/screens/scene_selection_screen.dart';
import 'package:boyfriend_camera/screens/smart_selection_screen.dart';
import 'package:boyfriend_camera/services/photo_repository.dart';
import 'package:boyfriend_camera/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyPhotoRepository extends PhotoRepository {
  @override
  Future<List<File>> listPhotos() async => const [];
}

class _SamplePhotoRepository extends PhotoRepository {
  @override
  Future<List<File>> listPhotos() async => List.generate(
    9,
    (index) => File(
      index.isEven
          ? 'assets/poses/pose_template_1.png'
          : 'assets/poses/pose_template_2.png',
    ),
  );
}

List<CapturedShot> get _sampleShots => List.generate(
  5,
  (index) => CapturedShot(
    file: File(
      index.isEven
          ? 'assets/poses/pose_template_1.png'
          : 'assets/poses/pose_template_2.png',
    ),
    score: 94 - index * 9,
    sceneName: '公园',
    poseName: scenePresets.first.poseNames[index % 3],
    capturedAt: DateTime(2026, 7, 17),
  ),
);

Widget _app(Widget home) =>
    MaterialApp(theme: buildAppTheme(fontFamily: 'QaChinese'), home: home);

const _qaFontPath = '/System/Library/Fonts/STHeiti Light.ttc';
final _flutterRoot =
    Platform.environment['FLUTTER_ROOT'] ?? '/Users/didi/flutter';
final _iconFontPath =
    '$_flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
final _canRunVisualQa =
    File(_qaFontPath).existsSync() && File(_iconFontPath).existsSync();

void main() {
  setUpAll(() async {
    if (!_canRunVisualQa) return;
    final bytes = await File(_qaFontPath).readAsBytes();
    final loader = FontLoader('QaChinese')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    final iconBytes = await File(_iconFontPath).readAsBytes();
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconBytes)));
    await iconLoader.load();
  });

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('visual QA', () {
    testWidgets('onboarding visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(_app(OnboardingScreen(onComplete: () {})));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OnboardingScreen),
        matchesGoldenFile('goldens/onboarding.png'),
      );
    });

    testWidgets('home visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 1121));
      await tester.pumpWidget(
        _app(
          AppShell(cameras: const [], photoRepository: _EmptyPhotoRepository()),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/home.png'),
      );
    });

    testWidgets('scene selection visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 981));
      await tester.pumpWidget(
        _app(SceneSelectionScreen(selected: scenePresets.first)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SceneSelectionScreen),
        matchesGoldenFile('goldens/scene-selection.png'),
      );
    });

    testWidgets('camera visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(
        _app(
          GuidedCameraScreen(
            cameras: const [],
            photoRepository: _EmptyPhotoRepository(),
            scene: scenePresets.first,
            manualScene: false,
            previewOverride: const ColoredBox(color: Color(0xFF111114)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(GuidedCameraScreen),
        matchesGoldenFile('goldens/camera.png'),
      );
    });

    testWidgets('capture complete visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(
        _app(CaptureCompleteScreen(shots: _sampleShots, onContinue: () {})),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CaptureCompleteScreen),
        matchesGoldenFile('goldens/capture-complete.png'),
      );
    });

    testWidgets('smart selection visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(_app(SmartSelectionScreen(shots: _sampleShots)));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SmartSelectionScreen),
        matchesGoldenFile('goldens/smart-selection.png'),
      );
    });

    testWidgets('album visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 733));
      await tester.pumpWidget(
        _app(
          AppShell(
            cameras: const [],
            photoRepository: _SamplePhotoRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('相册').last);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/album.png'),
      );
    });

    testWidgets('profile visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(
        _app(
          AppShell(
            cameras: const [],
            photoRepository: _SamplePhotoRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('我的').last);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/profile.png'),
      );
    });

    testWidgets('photo detail visual', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 1014));
      final shot = _sampleShots.first;
      await tester.pumpWidget(
        _app(PhotoDetailScreen(photo: shot.file, shot: shot)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(PhotoDetailScreen),
        matchesGoldenFile('goldens/photo-detail.png'),
      );
    });
  }, skip: !_canRunVisualQa);
}
