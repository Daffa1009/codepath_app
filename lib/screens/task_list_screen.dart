import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/task_item.dart';
import '../providers/task_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.tasks;

    return SafeArea(
      child: Column(
        children: [
          const AppHeader(title: 'Latihan'),
          if (provider.isLoading)
            const Expanded(
              child:
                  Center(child: CircularProgressIndicator()),
            )
          else if (tasks.isEmpty)
            const Expanded(
              child: Center(
                  child: Text('Belum ada tugas.',
                      style: TextStyle(color: AppColors.textMuted))),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: tasks.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final task = tasks[i];
                  return TaskCard(
                    task: task,
                    onTap: () =>
                        _showTaskDetail(context, task, provider),
                    onMarkDone: () => provider.markDone(task.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showTaskDetail(
      BuildContext context, TaskItem task, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isUrgent = task.urgency == TaskUrgency.mendesak;
        final urgencyBadgeColor =
            isUrgent ? AppColors.maroon : AppColors.primaryTeal;
        final urgencyLabel = isUrgent ? 'Mendesak' : 'Mendatang';
        final typeBadgeColor =
            task.type == TaskType.kuis ? AppColors.gold : AppColors.success;
        final typeLabel =
            task.type == TaskType.kuis ? 'Kuis' : 'Praktik';

        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Judul tugas
              Text(task.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),

              // Course title
              Text(task.courseTitle,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textMuted)),

              const SizedBox(height: 16),

              // Badge row
              Row(
                children: [
                  _badge(urgencyLabel, urgencyBadgeColor),
                  const SizedBox(width: 8),
                  _badge(typeLabel, typeBadgeColor),
                ],
              ),
              const SizedBox(height: 16),

              // Deadline
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy · HH:mm')
                        .format(task.deadline),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deskripsi
              if (task.description.isNotEmpty) ...[
                const Text('Deskripsi',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Text(task.description,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5)),
                const SizedBox(height: 20),
              ],

              // Tombol Tandai Selesai
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: task.isDone
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          provider.markDone(task.id);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.isDone
                        ? Colors.grey.shade300
                        : AppColors.primaryTeal,
                    foregroundColor:
                        task.isDone ? AppColors.textMuted : Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: AppColors.textMuted,
                  ),
                  icon: Icon(task.isDone
                      ? Icons.check_circle
                      : Icons.check),
                  label: Text(task.isDone
                      ? 'Sudah Selesai'
                      : 'Tandai Selesai'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
