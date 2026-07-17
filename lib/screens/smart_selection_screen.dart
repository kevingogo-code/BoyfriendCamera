import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import 'photo_detail_screen.dart';

class SmartSelectionScreen extends StatefulWidget {
  const SmartSelectionScreen({super.key, required this.shots});

  final List<CapturedShot> shots;

  @override
  State<SmartSelectionScreen> createState() => _SmartSelectionScreenState();
}

class _SmartSelectionScreenState extends State<SmartSelectionScreen> {
  ShotCategory _category = ShotCategory.recommended;
  final Set<String> _selected = {};

  late final List<CapturedShot> _sorted = [...widget.shots]
    ..sort((a, b) => b.score.compareTo(a.score));

  @override
  void initState() {
    super.initState();
    for (final shot in _sorted.take(2)) {
      _selected.add(shot.file.path);
    }
  }

  List<CapturedShot> get _visible {
    return [
      for (var index = 0; index < _sorted.length; index++)
        if (_sorted[index].categoryFor(index, _sorted.length) == _category)
          _sorted[index],
    ];
  }

  int _count(ShotCategory category) {
    var count = 0;
    for (var index = 0; index < _sorted.length; index++) {
      if (_sorted[index].categoryFor(index, _sorted.length) == category) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能选片'),
        actions: [
          TextButton(
            onPressed:
                () => setState(() {
                  _selected
                    ..clear()
                    ..addAll(_visible.map((shot) => shot.file.path));
                }),
            child: const Text(
              '全选',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 14),
            child: Row(
              children: [
                Expanded(child: _tab(ShotCategory.recommended, '推荐')),
                const SizedBox(width: 8),
                Expanded(child: _tab(ShotCategory.backup, '备选')),
                const SizedBox(width: 8),
                Expanded(child: _tab(ShotCategory.discard, '可删')),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: .76,
              ),
              itemCount: _visible.length,
              itemBuilder: (context, index) {
                final shot = _visible[index];
                final selected = _selected.contains(shot.file.path);
                return InkWell(
                  onTap:
                      () => setState(() {
                        if (selected) {
                          _selected.remove(shot.file.path);
                        } else {
                          _selected.add(shot.file.path);
                        }
                      }),
                  onLongPress:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => PhotoDetailScreen(
                                photo: shot.file,
                                shot: shot,
                              ),
                        ),
                      ),
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(13)),
                        child: ColoredBox(color: AppColors.fill),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(shot.file, fit: BoxFit.cover),
                      ),
                      Positioned(
                        left: 9,
                        top: 9,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.blue : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child:
                              selected
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 15,
                                  )
                                  : null,
                        ),
                      ),
                      if (_category == ShotCategory.recommended)
                        const Positioned(
                          right: 9,
                          top: 9,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '推荐',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Text(
                          shot.reason,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 15, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Text(
                    '已选 ${_selected.length} 张',
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('删除未选'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(98, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text('保存已选'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(ShotCategory category, String label) {
    final active = category == _category;
    return InkWell(
      onTap: () => setState(() => _category = category),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.blue : AppColors.fill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '$label (${_count(category)})',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
