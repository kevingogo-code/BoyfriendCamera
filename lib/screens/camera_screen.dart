import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pose_models.dart';
import '../services/composition_analyzer.dart';
import '../services/photo_repository.dart';
import '../services/pose_analyzer.dart';
import '../widgets/camera_overlays.dart';
import 'album_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.cameras,
    required this.photoRepository,
    this.startupError,
  });

  final List<CameraDescription> cameras;
  final PhotoRepository photoRepository;
  final Object? startupError;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  final PoseAnalyzer _poseAnalyzer = PoseAnalyzer();
  final CompositionAnalyzer _compositionAnalyzer = const CompositionAnalyzer();

  bool _initializing = false;
  bool _processingFrame = false;
  bool _capturing = false;
  DateTime _lastAnalysis = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastCompositionAnalysis = DateTime.fromMillisecondsSinceEpoch(0);
  String? _cameraError;
  String? _capturedPath;
  File? _latestPhoto;

  int _poseIndex = 0;
  double _smoothedScore = 0;
  String _instruction = '站在画面内';
  String _stateLabel = '检测中';
  String _compositionLabel = '自动居中';
  Color _guideColor = Colors.white70;

  double _poseScale = 1;
  double _gestureStartScale = 1;
  Offset _poseOffset = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureFocalStart = Offset.zero;
  Size _viewfinderSize = Size.zero;
  bool _hasManualPoseAdjustment = false;
  CompositionLayout? _autoLayout;

  PoseTemplate? get _activePose =>
      _poseIndex < 0 ? null : poseTemplates[_poseIndex];

  CompositionLayout get _activeLayout {
    final template = _activePose;
    if (template == null) {
      throw StateError('An active pose is required to calculate composition.');
    }
    return _autoLayout ?? CompositionLayout.defaultFor(template);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLatestPhoto();
    if (widget.startupError != null) {
      _cameraError = '无法读取相机：${widget.startupError}';
    } else if (widget.cameras.isEmpty) {
      _cameraError = '没有检测到可用相机';
    } else {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _loadLatestPhoto() async {
    try {
      final photo = await widget.photoRepository.latestPhoto();
      if (mounted) setState(() => _latestPhoto = photo);
    } catch (_) {
      // Storage plugins are not available in widget tests and may be
      // temporarily unavailable while the app is resuming.
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
        _activePose == null ||
        _capturedPath != null) {
      return;
    }
    try {
      await controller.startImageStream(_analyzeFrame);
    } catch (_) {
      // Taking a photo or a lifecycle transition can race the stream start.
    }
  }

  Future<void> _stopAnalysis() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {
        // The platform may have already stopped the stream.
      }
    }
  }

  void _analyzeFrame(CameraImage image) {
    final now = DateTime.now();
    final template = _activePose;
    if (template != null &&
        !_hasManualPoseAdjustment &&
        now.difference(_lastCompositionAnalysis) >=
            const Duration(milliseconds: 1500)) {
      _lastCompositionAnalysis = now;
      _applyCompositionResult(
        _compositionAnalyzer.analyze(image: image, template: template),
      );
    }
    if (_processingFrame ||
        now.difference(_lastAnalysis) < const Duration(milliseconds: 420)) {
      return;
    }
    final controller = _controller;
    final camera = _camera;
    final activeTemplate = _activePose;
    if (controller == null || camera == null || activeTemplate == null) return;
    _processingFrame = true;
    _lastAnalysis = now;
    _poseAnalyzer
        .analyze(
          image: image,
          camera: camera,
          deviceOrientation: controller.value.deviceOrientation,
          template: activeTemplate,
        )
        .then(_applyPoseResult)
        .catchError((Object error, StackTrace stack) {
          if (kDebugMode) debugPrint('Pose analysis failed: $error');
        })
        .whenComplete(() => _processingFrame = false);
  }

  void _applyCompositionResult(CompositionLayout layout) {
    if (!mounted || _hasManualPoseAdjustment || _capturedPath != null) return;
    setState(() {
      _autoLayout = layout;
      _compositionLabel = layout.label;
    });
  }

  void _applyPoseResult(PoseFrameResult? result) {
    if (!mounted || _activePose == null || _capturedPath != null) return;
    if (result == null) {
      setState(() {
        _smoothedScore = 0;
        _instruction = '站在画面内';
        _stateLabel = '检测中';
        _guideColor = const Color(0xFFFF6B6B);
      });
      return;
    }

    final template = _activePose!;
    final layout = _activeLayout;
    final score = _smoothedScore * .6 + result.match.score * .4;
    final person = result.keypoints.bounds;
    final targetHeight = layout.heightRatio * _poseScale;
    final targetWidth = targetHeight * template.aspectRatio;
    final targetCenter =
        layout.centerX +
        (_viewfinderSize.width == 0
            ? 0
            : _poseOffset.dx / _viewfinderSize.width);
    final sizeRatio = targetHeight <= 0 ? 1 : person.height / targetHeight;
    final horizontalOffset = person.centerX - targetCenter;

    late String instruction;
    late String state;
    late Color color;
    if (sizeRatio > 1.1) {
      instruction = '站得远一些';
      state = '人物太近';
      color = const Color(0xFF007AFF);
    } else if (sizeRatio < .9) {
      instruction = '站得近一些';
      state = '人物太远';
      color = const Color(0xFF007AFF);
    } else if (horizontalOffset < -targetWidth * .1) {
      instruction = '往右一点';
      state = '人物偏左';
      color = const Color(0xFF007AFF);
    } else if (horizontalOffset > targetWidth * .1) {
      instruction = '往左一点';
      state = '人物偏右';
      color = const Color(0xFF007AFF);
    } else if (score > 80) {
      instruction = '完美';
      state = '就绪';
      color = const Color(0xFF34C759);
    } else {
      instruction = result.match.suggestion;
      state = '调整姿势';
      color = score > 50 ? const Color(0xFFFFCC00) : const Color(0xFFFF6B6B);
    }
    setState(() {
      _smoothedScore = score;
      _instruction = instruction;
      _stateLabel = state;
      _guideColor = color;
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
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() => _capturedPath = photo.path);
    } catch (error) {
      _notify('拍照失败：$error');
      await _startAnalysis();
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _retake() async {
    final path = _capturedPath;
    if (path != null) {
      unawaited(File(path).delete().catchError((_) => File(path)));
    }
    setState(() => _capturedPath = null);
    await _startAnalysis();
    _notify('已返回拍照');
  }

  Future<void> _savePhoto() async {
    final path = _capturedPath;
    if (path == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final stored = await widget.photoRepository.savePhoto(path);
      if (!mounted) return;
      setState(() {
        _latestPhoto = stored;
        _capturedPath = null;
      });
      unawaited(File(path).delete().catchError((_) => File(path)));
      _notify('已保存到相册');
      await _startAnalysis();
    } catch (error) {
      _notify('保存失败：$error');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _openAlbum() async {
    await _stopAnalysis();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumScreen(repository: widget.photoRepository),
      ),
    );
    await _loadLatestPhoto();
    await _startAnalysis();
  }

  Future<void> _cyclePose() async {
    final next = (_poseIndex + 1) % poseTemplates.length;
    setState(() {
      _poseIndex = next;
      _poseScale = 1;
      _poseOffset = Offset.zero;
      _hasManualPoseAdjustment = false;
      _autoLayout = null;
      _compositionLabel = '分析背景中';
      _lastCompositionAnalysis = DateTime.fromMillisecondsSinceEpoch(0);
      _smoothedScore = 0;
      _instruction = '站在轮廓内';
      _stateLabel = '检测中';
      _guideColor = const Color(0xFFFF6B6B);
    });
    await _startAnalysis();
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1600),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captured = _capturedPath;
    if (captured != null) return _buildPreview(captured);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child:
            _cameraError != null
                ? _buildCameraError()
                : _controller?.value.isInitialized == true
                ? _buildCamera()
                : const Center(child: CircularProgressIndicator()),
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
            Text(_cameraError!, textAlign: TextAlign.center),
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
        _buildTopBar(),
        if (_activePose != null) _buildScoreBar(),
        Expanded(child: _buildViewfinder()),
        Container(
          height: 54,
          alignment: Alignment.center,
          color: Colors.black.withValues(alpha: .85),
          child: Text(
            _instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  _instruction == '完美' ? const Color(0xFF34C759) : Colors.white,
              fontSize: _instruction == '完美' ? 28 : 19,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.black.withValues(alpha: .88),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_city_outlined, size: 17),
                SizedBox(width: 6),
                Text('街拍', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _guideColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _stateLabel,
                  style: TextStyle(color: _guideColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.black.withValues(alpha: .76),
      child: Row(
        children: [
          Text(
            _compositionLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            '贴合度：${_smoothedScore.round()}%',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _smoothedScore / 100,
                minHeight: 6,
                color: _guideColor,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    final controller = _controller!;
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewfinderSize = constraints.biggest;
        final previewSize = controller.value.previewSize!;
        final template = _activePose;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: previewSize.height,
                  height: previewSize.width,
                  child: CameraPreview(controller),
                ),
              ),
              const CameraGrid(),
              if (template != null)
                _buildSilhouette(template, constraints.biggest),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSilhouette(PoseTemplate template, Size viewport) {
    final layout = _activeLayout;
    final height = viewport.height * layout.heightRatio;
    final width = height * template.aspectRatio;
    final left = viewport.width * layout.centerX - width / 2;
    final top = viewport.height * layout.centerY - height / 2;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.translate(
        offset: _poseOffset,
        child: Transform.scale(
          scale: _poseScale,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _gestureStartScale = _poseScale;
              _gestureStartOffset = _poseOffset;
              _gestureFocalStart = details.focalPoint;
            },
            onScaleUpdate: (details) {
              setState(() {
                _hasManualPoseAdjustment = true;
                _compositionLabel = '手动调整';
                _poseScale = (_gestureStartScale * details.scale).clamp(
                  .45,
                  1.45,
                );
                _poseOffset =
                    _gestureStartOffset +
                    details.focalPoint -
                    _gestureFocalStart;
              });
            },
            child: Opacity(
              opacity: .78,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(_guideColor, BlendMode.srcIn),
                child: Image.asset(template.asset, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(30, 14, 30, 22),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RoundControl(
            icon: Icons.photo_library_outlined,
            label: '相册',
            onPressed: _openAlbum,
            child:
                _latestPhoto == null
                    ? null
                    : Image.file(
                      _latestPhoto!,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                      errorBuilder:
                          (_, __, ___) =>
                              const Icon(Icons.photo_library_outlined),
                    ),
          ),
          Semantics(
            button: true,
            label: '拍照',
            child: GestureDetector(
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
          ),
          RoundControl(
            icon: Icons.accessibility_new,
            label: '切换姿势轮廓',
            active: _activePose != null,
            onPressed: _cyclePose,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(String path) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.black,
              child: const Row(
                children: [
                  Text(
                    '照片预览',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(Icons.check_circle, color: Color(0xFF34C759), size: 17),
                  SizedBox(width: 6),
                  Text('已就绪', style: TextStyle(color: Color(0xFF34C759))),
                ],
              ),
            ),
            Expanded(
              child: Image.file(
                File(path),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            Container(
              height: 112,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _capturing ? null : _retake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重拍'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _capturing ? null : _savePhoto,
                      icon:
                          _capturing
                              ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.download_done),
                      label: const Text('保存'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
