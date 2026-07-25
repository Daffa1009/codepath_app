import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/roadmap.dart';
import 'custom_progress_bar.dart';

/// Card jalur belajar (roadmap) — dipakai di Beranda dan Roadmap List Screen.
class CourseCard extends StatelessWidget {
  final Roadmap roadmap;
  final VoidCallback onTap;

  const CourseCard({super.key, required this.roadmap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: roadmap.iconColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(roadmap.icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(roadmap.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  CustomProgressBar(
                    progress: roadmap.progress,
                    fillColor: roadmap.progress >= 1
                        ? AppColors.success
                        : AppColors.gold,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${roadmap.progressPercent}% Selesai',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Ketuk untuk Detail Kursus',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
