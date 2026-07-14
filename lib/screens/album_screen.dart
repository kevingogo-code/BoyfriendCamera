import 'dart:io';

import 'package:flutter/material.dart';

import '../services/photo_repository.dart';
import 'photo_view_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.repository});

  final PhotoRepository repository;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<File>> _photos;

  @override
  void initState() {
    super.initState();
    _photos = widget.repository.listPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('相册'),
        actions: [
          FutureBuilder<List<File>>(
            future: _photos,
            builder:
                (_, snapshot) => Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Center(
                    child: Text(
                      '共 ${snapshot.data?.length ?? 0} 张',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
      body: FutureBuilder<List<File>>(
        future: _photos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final photos = snapshot.data ?? const <File>[];
          if (photos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 72,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text('暂无照片', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: photos.length,
            itemBuilder:
                (context, index) => InkWell(
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PhotoViewScreen(photo: photos[index]),
                        ),
                      ),
                  child: Hero(
                    tag: photos[index].path,
                    child: Image.file(
                      photos[index],
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                      errorBuilder:
                          (_, __, ___) => const ColoredBox(
                            color: Color(0xFF1C1C1E),
                            child: Icon(Icons.broken_image_outlined),
                          ),
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }
}
