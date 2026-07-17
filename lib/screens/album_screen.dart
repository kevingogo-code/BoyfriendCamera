import 'dart:io';

import 'package:flutter/material.dart';

import '../services/photo_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'photo_detail_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.repository});

  final PhotoRepository repository;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late final Future<List<File>> _photos = widget.repository.listPhotos();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<File>>(
        future: _photos,
        builder: (context, snapshot) {
          final photos = snapshot.data ?? const <File>[];
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 34, 16, 0),
                sliver: SliverList.list(
                  children: [
                    PageTitle(
                      '相册',
                      trailing: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '共 ${photos.length} 张照片 · 推荐 ${(photos.length * .6).round()} 张',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '公园 · 街拍 · 旅行',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '全部照片',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (snapshot.connectionState != ConnectionState.done)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (photos.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '还没有照片，去拍一组吧',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: .82,
                        ),
                    itemCount: photos.length,
                    itemBuilder:
                        (context, index) => PhotoTile(
                          file: photos[index],
                          recommended: index % 3 != 1,
                          radius: 8,
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder:
                                      (_) => PhotoDetailScreen(
                                        photo: photos[index],
                                      ),
                                ),
                              ),
                        ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
