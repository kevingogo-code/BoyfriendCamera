import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/photo_repository.dart';
import '../theme/app_theme.dart';
import 'album_screen.dart';
import 'capture_complete_screen.dart';
import 'guided_camera_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.cameras,
    required this.photoRepository,
    this.startupError,
  });

  final List<CameraDescription> cameras;
  final PhotoRepository photoRepository;
  final Object? startupError;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  ScenePreset _scene = scenePresets.first;
  int _refreshKey = 0;

  Future<void> _startCapture(ScenePreset scene, {bool manual = false}) async {
    final shots = await Navigator.of(context).push<List<CapturedShot>>(
      MaterialPageRoute(
        builder:
            (_) => GuidedCameraScreen(
              cameras: widget.cameras,
              photoRepository: widget.photoRepository,
              scene: scene,
              manualScene: manual,
              startupError: widget.startupError,
            ),
      ),
    );
    if (!mounted || shots == null || shots.isEmpty) return;
    setState(() => _refreshKey++);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => CaptureCompleteScreen(
              shots: shots,
              onContinue: () {
                Navigator.of(context).pop();
                _startCapture(scene, manual: manual);
              },
            ),
      ),
    );
    if (mounted) setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        key: ValueKey('home-$_refreshKey'),
        repository: widget.photoRepository,
        selectedScene: _scene,
        onSceneChanged: (scene) => setState(() => _scene = scene),
        onStartCapture: (scene, manual) => _startCapture(scene, manual: manual),
      ),
      AlbumScreen(
        key: ValueKey('album-$_refreshKey'),
        repository: widget.photoRepository,
      ),
      ProfileScreen(repository: widget.photoRepository),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 78,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera, color: AppColors.blue),
            label: '拍照',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library, color: AppColors.blue),
            label: '相册',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.blue),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
