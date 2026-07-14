import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class PhotoRepository {
  static const albumName = 'BoyfriendCamera';

  Future<Directory> _photoDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/photos');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<List<File>> listPhotos() async {
    final directory = await _photoDirectory();
    final photos =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.jpg'))
            .toList();
    photos.sort((a, b) => b.path.compareTo(a.path));
    return photos;
  }

  Future<File?> latestPhoto() async {
    final photos = await listPhotos();
    return photos.isEmpty ? null : photos.first;
  }

  Future<File> savePhoto(String sourcePath) async {
    final directory = await _photoDirectory();
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final filename =
        'BF_${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}_'
        '${now.millisecond.toString().padLeft(3, '0')}.jpg';
    final stored = await File(sourcePath).copy('${directory.path}/$filename');

    final hasAccess = await Gal.hasAccess();
    if (hasAccess || await Gal.requestAccess()) {
      await Gal.putImage(stored.path, album: albumName);
    } else {
      await stored.delete();
      throw const FileSystemException('没有相册写入权限');
    }
    return stored;
  }
}
