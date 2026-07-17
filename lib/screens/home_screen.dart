import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/photo_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'photo_detail_screen.dart';
import 'scene_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.selectedScene,
    required this.onSceneChanged,
    required this.onStartCapture,
  });

  final PhotoRepository repository;
  final ScenePreset selectedScene;
  final ValueChanged<ScenePreset> onSceneChanged;
  final void Function(ScenePreset scene, bool manual) onStartCapture;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<File>> _photos = widget.repository.listPhotos();

  Future<void> _chooseScene() async {
    final result = await Navigator.of(context).push<ScenePreset>(
      MaterialPageRoute(
        builder: (_) => SceneSelectionScreen(selected: widget.selectedScene),
      ),
    );
    if (result != null) widget.onSceneChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 34, 16, 22),
            sliver: SliverList.list(
              children: [
                PageTitle(
                  'AI 相机',
                  trailing: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 52),
                Center(
                  child: InkWell(
                    onTap:
                        () =>
                            widget.onStartCapture(widget.selectedScene, false),
                    borderRadius: BorderRadius.circular(44),
                    child: const Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.blue,
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '开始拍摄',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 42),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final scene = scenePresets[index];
                      return SceneChip(
                        label: scene.name,
                        icon: scene.icon,
                        selected: scene.id == widget.selectedScene.id,
                        onTap: () {
                          if (scene.id == widget.selectedScene.id) {
                            _chooseScene();
                          } else {
                            widget.onSceneChanged(scene);
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 35),
                const Text(
                  '最近拍摄',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          FutureBuilder<List<File>>(
            future: _photos,
            builder: (context, snapshot) {
              final photos = snapshot.data ?? const <File>[];
              final display = photos.take(6).toList();
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: .89,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final file = index < display.length ? display[index] : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PhotoTile(
                            file: file,
                            onTap:
                                file == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) =>
                                                PhotoDetailScreen(photo: file),
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _dateLabel(file),
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }, childCount: display.isEmpty ? 6 : display.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 30, bottom: 18),
              child: Text(
                '拍5张 · AI 帮你选出最好的一张',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(File? file) {
    if (file == null) return '—';
    final modified = file.lastModifiedSync();
    return '${modified.month}月${modified.day}日';
  }
}
