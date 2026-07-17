import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';
import '../models/pose_models.dart';
import '../services/composition_analyzer.dart';
import '../services/photo_repository.dart';
import '../services/pose_analyzer.dart';
import '../services/scene_classifier.dart';
import '../theme/app_theme.dart';
import '../widgets/camera_overlays.dart';

class GuidedCameraScreen extends StatefulWidget {
  const GuidedCameraScreen({
    super.key,
    required this.cameras,
    required this.photoRepository,
    required this.scene,
    required this.manualScene,
    this.startupError,
    this.previewOverride,
  });

  final List<CameraDescription> cameras;
  final PhotoRepository photoRepository;
  final ScenePreset scene;
  final bool manualScene;
  final Object? startupError;
  final Widget? previewOverride;

  @override
  State<GuidedCameraScreen> createState() => _GuidedCameraScreenState();
}

class _GuidedCameraScreenState extends State<GuidedCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  final PoseAnalyzer _poseAnalyzer = PoseAnalyzer();
  final SceneClassifier _sceneClassifier = SceneClassifier();
  final CompositionAnalyzer _compositionAnalyzer = const CompositionAnalyzer();
  final List<CapturedShot> _shots = [];

  bool _initializing = false;
  bool _processingPose = false;
  bool _processingScene = false;
  bool _capturing = false;
  bool _flashOn = false;
  DateTime _lastPose = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastScene = DateTime.fromMillisecondsSinceEpoch(0);
  String? _cameraError;
  int _poseIndex = 0;
  int _shotScore = 70;
  String _instruction = '人物站入画面，手机保持稳定';
  String _compositionLabel = '正在优化构图';
  SceneClassification? _scene;
  late CompositionLayout _layout = CompositionLayout.defaultFor(_template);

  PoseTemplate get _template =>
      poseTemplates[_poseIndex % poseTemplates.length];
  String get _sceneName {
    if (widget.manualScene) return widget.scene.name;
    final detected = _scene;
    if (detected == null) return widget.scene.name;
    return detected.label == 'urban_nature' ? '公园' : '街拍';
  }

  SceneClassification get _manualClassification {
    final label = switch (widget.scene.id) {
      'park' => 'urban_nature',
      'street' => 'street',
      'indoor' => 'building',
      'night' => 'busy',
      'travel' => 'building',
      'food' => 'storefront',
      _ => 'street',
    };
    return SceneClassification(label: label, confidence: .9);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.previewOverride != null) return;
    if (widget.startupError != null) {
      _cameraError = '无法读取相机：${widget.startupError}';
    } else if (widget.cameras.isEmpty) {
      _cameraError = '没有检测到可用相机';
    } else {
      unawaited(_initializeCamera());
    }
    unawaited(_loadSceneModel());
  }

  Future<void> _loadSceneModel() async {
    try {
      await _sceneClassifier.load();
    } catch (error) {
      if (kDebugMode) debugPrint('Scene classifier failed: $error');
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializing || widget.cameras.isEmpty) return;
    _initializing = true;
    final camera = widget.cameras.firstWhere(
      (item) => item.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
    );
    try {
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _controller?.dispose();
      setState(() {
        _camera = camera;
        _controller = controller;
        _cameraError = null;
      });
      await _startAnalysis();
    } on CameraException catch (error) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _cameraError =
              error.code == 'CameraAccessDenied'
                  ? '需要相机权限才能拍照，请在系统设置中允许访问。'
                  : '相机启动失败：${error.description ?? error.code}';
        });
      }
    } catch (error) {
      await controller.dispose();
      if (mounted) setState(() => _cameraError = '相机启动失败：$error');
    } finally {
      _initializing = false;
    }
  }

  Future<void> _startAnalysis() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages ||
        _capturing) {
      return;
    }
    try {
      await controller.startImageStream(_analyzeFrame);
    } catch (_) {
      // Lifecycle and capture may race the stream transition.
    }
  }

  Future<void> _stopAnalysis() async {
    final controller = _controller;
    if (controller?.value.isStreamingImages == true) {
      try {
        await controller!.stopImageStream();
      } catch (_) {}
    }
  }

  void _analyzeFrame(CameraImage image) {
    final now = DateTime.now();
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return;

    if (!_processingPose &&
        now.difference(_lastPose) >= const Duration(milliseconds: 420)) {
      _processingPose = true;
      _lastPose = now;
      _poseAnalyzer
          .analyze(
            image: image,
            camera: camera,
            deviceOrientation: controller.value.deviceOrientation,
            template: _template,
          )
          .then(_applyPose)
          .catchError((Object error, StackTrace stack) {
            if (kDebugMode) debugPrint('Pose analysis failed: $error');
          })
          .whenComplete(() => _processingPose = false);
    }

    if (!_processingScene &&
        now.difference(_lastScene) >= const Duration(milliseconds: 1800)) {
      _processingScene = true;
      _lastScene = now;
      try {
        if (!widget.manualScene) {
          final candidate = _sceneClassifier.analyze(image);
          if (candidate != null && candidate.confidence >= .6) {
            _scene = candidate;
          }
        }
        final activeScene = widget.manualScene ? _manualClassification : _scene;
        final layout = _compositionAnalyzer.analyze(
          image: image,
          camera: camera,
          deviceOrientation: controller.value.deviceOrientation,
          template: _template,
          scene: activeScene,
        );
        if (mounted) {
          setState(() {
            _layout = layout;
            _compositionLabel = layout.label;
          });
        }
      } catch (error) {
        if (kDebugMode) debugPrint('Composition analysis failed: $error');
      } finally {
        _processingScene = false;
      }
    }
  }

  void _applyPose(PoseFrameResult? result) {
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _shotScore = 35;
        _instruction = '人物站入画面，手机保持稳定';
      });
      return;
    }

    final person = result.keypoints.bounds;
    final targetHeight = _layout.heightFor(_template);
    final sizeRatio = targetHeight <= 0 ? 1 : person.height / targetHeight;
    final horizontalOffset = person.centerX - _layout.centerX;
    final sizeScore = (1 - (sizeRatio - 1).abs() / .4).clamp(0.0, 1.0);
    final positionScore = (1 - horizontalOffset.abs() / .25).clamp(0.0, 1.0);
    final qualityScore =
        result.match.score * .55 + sizeScore * 25 + positionScore * 20;
    var instruction = result.match.suggestion;
    if (sizeRatio > 1.12) {
      instruction = '手机后退一点，给环境留出空间';
    } else if (sizeRatio < .86) {
      instruction = '手机放低一点，向前靠近半步';
    } else if (horizontalOffset < -.09) {
      instruction = '手机往左移，让人物靠近构图线';
    } else if (horizontalOffset > .09) {
      instruction = '手机往右移，让人物靠近构图线';
    } else if (result.match.score >= 78) {
      instruction = '保持这个角度，可以拍了';
    }
    setState(() {
      _shotScore = qualityScore.round().clamp(0, 100);
      _instruction = instruction;
    });
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      await _stopAnalysis();
      final capture = await controller.takePicture();
      final stored = await widget.photoRepository.savePhoto(capture.path);
      unawaited(
        File(capture.path).delete().catchError((_) => File(capture.path)),
      );
      if (!mounted) return;
      setState(() {
        _shots.add(
          CapturedShot(
            file: stored,
            score: _shotScore,
            sceneName: _sceneName,
            poseName:
                widget.scene.poseNames[_poseIndex %
                    widget.scene.poseNames.length],
            capturedAt: DateTime.now(),
          ),
        );
      });
      HapticFeedback.mediumImpact();
      if (_shots.length >= 5) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (mounted) Navigator.of(context).pop(List<CapturedShot>.from(_shots));
        return;
      }
    } catch (error) {
      _notify('拍照失败：$error');
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        await _startAnalysis();
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = !_flashOn;
    try {
      await controller.setFlashMode(next ? FlashMode.always : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (_) {
      _notify('当前设备不支持闪光灯');
    }
  }

  void _selectPose(int index) {
    setState(() {
      _poseIndex = index;
      _layout = CompositionLayout.defaultFor(_template);
      _shotScore = 60;
      _instruction = '正在分析人物和拍摄角度';
    });
  }

  void _finish() {
    Navigator.of(
      context,
    ).pop(_shots.isEmpty ? null : List<CapturedShot>.from(_shots));
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xE61C1C1E),
        ),
      );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _controller;
      _controller = null;
      unawaited(controller?.dispose());
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      unawaited(_initializeCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    unawaited(_poseAnalyzer.dispose());
    _sceneClassifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child:
              widget.previewOverride != null
                  ? _buildCamera()
                  : _cameraError != null
                  ? _buildCameraError()
                  : _controller?.value.isInitialized == true
                  ? _buildCamera()
                  : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 60,
              color: Colors.white54,
            ),
            const SizedBox(height: 18),
            Text(
              _cameraError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: _initializeCamera, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              IconButton(
                onPressed: _finish,
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const Spacer(),
              Text(
                _sceneName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.manualScene ? '手动' : '自动',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleFlash,
                icon: Icon(
                  _flashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 438,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _cameraPreview(),
                  const CameraGrid(),
                  const _GuideFrame(),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xC9000000),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            color: AppColors.green,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _compositionLabel,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 123,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(80, 20, 80, 0),
            scrollDirection: Axis.horizontal,
            itemCount: widget.scene.poseNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 22),
            itemBuilder: (context, index) {
              final active = index == _poseIndex;
              return InkWell(
                onTap: () => _selectPose(index),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? AppColors.blue : Colors.transparent,
                        ),
                      ),
                      foregroundDecoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            poseTemplates[index % poseTemplates.length].asset,
                          ),
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            active ? AppColors.blue : Colors.white54,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.scene.poseNames[index],
                      style: TextStyle(
                        color: active ? AppColors.blue : Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF171719),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.blue,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _instruction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 149,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Transform.translate(
                offset: const Offset(0, -20),
                child: SizedBox.square(
                  dimension: 44,
                  child:
                      _shots.isEmpty
                          ? const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF303033),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.white54,
                            ),
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _shots.last.file,
                              fit: BoxFit.cover,
                            ),
                          ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _capturing ? null : _takePhoto,
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _capturing ? Colors.white54 : Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已拍 ${_shots.length}/5',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: IconButton(
                  onPressed: _shots.isEmpty ? null : _finish,
                  icon: Icon(
                    Icons.cloud_done_outlined,
                    color: _shots.isEmpty ? Colors.white38 : Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cameraPreview() {
    if (widget.previewOverride != null) return widget.previewOverride!;
    final controller = _controller!;
    final size = controller.value.previewSize!;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.height,
        height: size.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _GuideFrame extends StatelessWidget {
  const _GuideFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: .7),
        ),
        child: Stack(
          children: const [
            Positioned(left: 0, top: 0, child: _Corner(quarterTurns: 0)),
            Positioned(right: 0, top: 0, child: _Corner(quarterTurns: 1)),
            Positioned(right: 0, bottom: 0, child: _Corner(quarterTurns: 2)),
            Positioned(left: 0, bottom: 0, child: _Corner(quarterTurns: 3)),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.quarterTurns});
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.blue, width: 1.4),
            top: BorderSide(color: AppColors.blue, width: 1.4),
          ),
        ),
      ),
    );
  }
}
