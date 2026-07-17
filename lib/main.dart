import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_preferences.dart';
import 'services/photo_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  List<CameraDescription> cameras = const [];
  Object? startupError;
  try {
    cameras = await availableCameras();
  } catch (error) {
    startupError = error;
  }
  final preferences = AppPreferences();
  final showOnboarding = await preferences.shouldShowOnboarding();

  runApp(
    BoyfriendCameraApp(
      cameras: cameras,
      startupError: startupError,
      photoRepository: PhotoRepository(),
      preferences: preferences,
      showOnboarding: showOnboarding,
    ),
  );
}

class BoyfriendCameraApp extends StatefulWidget {
  const BoyfriendCameraApp({
    super.key,
    required this.cameras,
    required this.photoRepository,
    this.preferences,
    this.startupError,
    this.showOnboarding = false,
  });

  final List<CameraDescription> cameras;
  final PhotoRepository photoRepository;
  final AppPreferences? preferences;
  final Object? startupError;
  final bool showOnboarding;

  @override
  State<BoyfriendCameraApp> createState() => _BoyfriendCameraAppState();
}

class _BoyfriendCameraAppState extends State<BoyfriendCameraApp> {
  late bool _showOnboarding = widget.showOnboarding;

  Future<void> _finishOnboarding() async {
    await widget.preferences?.completeOnboarding();
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI 相机',
      theme: buildAppTheme(),
      home:
          _showOnboarding
              ? OnboardingScreen(onComplete: _finishOnboarding)
              : AppShell(
                cameras: widget.cameras,
                photoRepository: widget.photoRepository,
                startupError: widget.startupError,
              ),
    );
  }
}
