import 'dart:io';

import 'package:flutter/material.dart';

import '../services/photo_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.repository});

  final PhotoRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _voice = false;
  bool _autoComposition = true;
  bool _smartSelection = true;
  late final Future<List<File>> _photos = widget.repository.listPhotos();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.fill,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 34, 16, 24),
          children: [
            const PageTitle('我的'),
            const SizedBox(height: 20),
            _card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.fill,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.secondaryText,
                  ),
                ),
                title: const Text(
                  '用户昵称',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: FutureBuilder<List<File>>(
                  future: _photos,
                  builder:
                      (_, snapshot) =>
                          Text('已拍摄 ${snapshot.data?.length ?? 0} 次'),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<File>>(
              future: _photos,
              builder: (_, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _card(
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _stat('$count', '总拍摄'),
                        const VerticalDivider(width: 1),
                        _stat('${(count * .6).round()}', '推荐照片'),
                        const VerticalDivider(width: 1),
                        _stat('92%', '出片率', blue: true),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _setting(
                    Icons.settings_outlined,
                    '拍摄偏好',
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.fill,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            child: Text('公园', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                  _divider(),
                  _setting(
                    Icons.volume_up_outlined,
                    '语音提示',
                    trailing: Switch(
                      value: _voice,
                      onChanged: (value) => setState(() => _voice = value),
                    ),
                  ),
                  _divider(),
                  _setting(
                    Icons.grid_on_outlined,
                    '自动构图',
                    trailing: Switch(
                      value: _autoComposition,
                      onChanged:
                          (value) => setState(() => _autoComposition = value),
                    ),
                  ),
                  _divider(),
                  _setting(
                    Icons.auto_awesome_outlined,
                    '智能选片',
                    trailing: Switch(
                      value: _smartSelection,
                      onChanged:
                          (value) => setState(() => _smartSelection = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _setting(
                    Icons.info_outline,
                    '关于 AI 相机',
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  _divider(),
                  _setting(
                    Icons.verified_user_outlined,
                    '版本',
                    trailing: const Text(
                      '1.1.0',
                      style: TextStyle(color: AppColors.secondaryText),
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

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _stat(String value, String label, {bool blue = false}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: blue ? AppColors.blue : AppColors.text,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _setting(IconData icon, String label, {required Widget trailing}) =>
      SizedBox(
        height: 54,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: AppColors.secondaryText, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            trailing,
            const SizedBox(width: 10),
          ],
        ),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 50, color: AppColors.line);
}
