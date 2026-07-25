import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Progress bar rounded pill, dipakai di card roadmap & detail screen.
class CustomProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final Color fillColor;
  final double height;

  const CustomProgressBar({
    super.key,
    required this.progress,
    this.fillColor = AppColors.gold,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                height: height,
                width: constraints.maxWidth,
                color: const Color(0xFFDDDDDD),
              ),
              Container(
                height: height,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                color: fillColor,
              ),
            ],
          );
        },
      ),
    );
  }
}
