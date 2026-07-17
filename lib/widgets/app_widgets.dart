import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    this.file,
    this.onTap,
    this.recommended = false,
    this.radius = 15,
  });

  final File? file;
  final VoidCallback? onTap;
  final bool recommended;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fill,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (file != null)
              Image.file(
                file!,
                fit: BoxFit.cover,
                cacheWidth: 520,
                errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
              )
            else
              const _PhotoPlaceholder(),
            if (recommended)
              const Positioned(
                right: 7,
                top: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.fill,
      child: Center(
        child: Icon(Icons.image_outlined, size: 34, color: Color(0xFF96969D)),
      ),
    );
  }
}

class SceneChip extends StatelessWidget {
  const SceneChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.blue : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
