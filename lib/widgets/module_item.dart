import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/roadmap_item.dart';

/// Baris list video dalam Roadmap Detail Screen — pakai icon check
/// (selesai) atau play (belum) sesuai desain asli.
///
/// Dibungkus Material widget untuk menyediakan Material ancestor
/// yang dibutuhkan oleh InkWell.
class ModuleItem extends StatelessWidget {
  final RoadmapItem item;
  final VoidCallback onTap;

  const ModuleItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isCompleted ? Icons.check : Icons.play_arrow,
                    color: item.isCompleted ? Colors.black87 : AppColors.maroon,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        'by ${item.channelName} · ${item.durationLabel}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
