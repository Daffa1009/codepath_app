import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/task_item.dart';

/// Card tugas/kuis dengan badge urgensi (Mendatang/Mendesak),
/// centang selesai, dan visual fade-out untuk item sudah selesai.
class TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onTap;
  final VoidCallback? onMarkDone;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = task.urgency == TaskUrgency.mendesak;
    final badgeColor = isUrgent ? AppColors.maroon : AppColors.primaryTeal;
    final badgeLabel = isUrgent ? 'Mendesak' : 'Mendatang';
    final isDone = task.isDone;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Opacity(
          // Pudarkan kalau sudah selesai
          opacity: isDone ? 0.55 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isDone) ...[
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(task.courseTitle,
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(task.title,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Deadline: ${DateFormat('d MMM yyyy, HH:mm').format(task.deadline)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                // Tombol Tandai Selesai
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        isDone ? null : onMarkDone,
                    style: TextButton.styleFrom(
                      foregroundColor: isDone
                          ? AppColors.textMuted
                          : AppColors.primaryTeal,
                    ),
                    icon: Icon(isDone ? Icons.check_circle : Icons.check),
                    label: Text(isDone ? 'Sudah Selesai' : 'Tandai Selesai'),
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
