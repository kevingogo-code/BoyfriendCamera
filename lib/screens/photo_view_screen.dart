import 'dart:io';

import 'package:flutter/material.dart';

class PhotoViewScreen extends StatelessWidget {
  const PhotoViewScreen({super.key, required this.photo});

  final File photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: .75),
        title: Text(_displayName(photo.path)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.file(photo, fit: BoxFit.contain),
        ),
      ),
    );
  }

  String _displayName(String path) {
    final filename = path.split(Platform.pathSeparator).last;
    return filename.replaceFirst('BF_', '').replaceFirst('.jpg', '');
  }
}
