import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/camera_screen.dart';
import 'services/photo_repository.dart';

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

  runApp(
    BoyfriendCameraApp(
      cameras: cameras,
      startupError: startupError,
      photoRepository: PhotoRepository(),
    ),
  );
}

class BoyfriendCameraApp extends StatelessWidget {
  const BoyfriendCameraApp({
    super.key,
    required this.cameras,
    required this.photoRepository,
    this.startupError,
  });

  final List<CameraDescription> cameras;
  final PhotoRepository photoRepository;
  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '男友相机',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFF34C759),
          surface: Color(0xFF1C1C1E),
        ),
        useMaterial3: true,
      ),
      home: CameraScreen(
        cameras: cameras,
        photoRepository: photoRepository,
        startupError: startupError,
      ),
    );
  }
}
