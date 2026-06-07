import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

String initialsFromName(String? name, {String fallback = 'U'}) {
  final parts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return fallback.toUpperCase();

  final firstInitial = parts.first.substring(0, 1);
  final lastInitial = parts.length > 1 ? parts.last.substring(0, 1) : '';
  return '$firstInitial$lastInitial'.toUpperCase();
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    required this.size,
    this.backgroundColor = AppColors.accent,
  });

  final String? name;
  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initialsFromName(name),
        maxLines: 1,
        style: AppTextStyles.headingMedium.copyWith(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
