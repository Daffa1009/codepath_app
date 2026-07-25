import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/roadmap_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/course_card.dart';
import '../widgets/task_card.dart';
import 'profile_screen.dart';
import 'roadmap_detail_screen.dart';
import 'video_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final String namaLengkap;
  final String username;

  const HomeScreen({
    super.key,
    this.namaLengkap = '',
    this.username = '',
  });

  @override
  Widget build(BuildContext context) {
    final roadmapProvider = context.watch<RoadmapProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final lastRoadmap = roadmapProvider.lastInProgress;
    final recommended = roadmapProvider.recommendedNext;
    final upcomingTasks = taskProvider.upcoming.take(2).toList();

    // Nama tampilan: prioritaskan namaLengkap, fallback ke username
    final displayName =
        namaLengkap.isNotEmpty ? namaLengkap : (username.isNotEmpty ? username : 'Pengguna');

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              color: AppColors.primaryTeal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child:
                          Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hallo, $displayName',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white)),
                      Text('Semangat Belajar Hari Ini',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress overview card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: roadmapProvider.isLoading
                        ? const Center(
                            child: SizedBox(
                              height: 36,
                              width: 36,
                              child: CircularProgressIndicator(
                                  color: AppColors.gold, strokeWidth: 3),
                            ),
                          )
                        : Row(
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: roadmapProvider.totalRoadmaps == 0
                                          ? 0
                                          : roadmapProvider.completedRoadmaps /
                                              roadmapProvider.totalRoadmaps,
                                      backgroundColor: Colors.white24,
                                      color: AppColors.gold,
                                      strokeWidth: 6,
                                    ),
                                    Text(
                                      '${roadmapProvider.totalRoadmaps == 0 ? 0 : (roadmapProvider.completedRoadmaps / roadmapProvider.totalRoadmaps * 100).round()}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Progres Belajar',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: Colors.white70)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${roadmapProvider.completedRoadmaps} dari ${roadmapProvider.totalRoadmaps} jalur belajar',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),

                  // Loading state saat data belum tersedia
                  if (roadmapProvider.isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: AppColors.primaryTeal),
                      ),
                    ),
                  ] else ...[
                    // Lanjutkan Belajar
                    if (lastRoadmap != null) ...[
                      Text('Lanjutkan Belajar',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      CourseCard(
                        roadmap: lastRoadmap,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoadmapDetailScreen(
                                roadmapId: lastRoadmap.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Rekomendasi
                    if (recommended != null) ...[
                      Text('Rekomendasi Untukmu',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Berdasarkan progres belajarmu terakhir',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VideoDetailScreen(item: recommended),
                          ),
                        ),
                        borderRadius:
                            BorderRadius.circular(AppRadius.card),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius:
                                BorderRadius.circular(AppRadius.card),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.play_arrow,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(recommended.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      'by ${recommended.channelName} · ${recommended.durationLabel}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ],

                  // Latihan Mendatang
                  Text('Latihan Mendatang',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (taskProvider.isLoading)
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryTeal))
                  else if (upcomingTasks.isEmpty)
                    Text('Tidak ada tugas mendatang.',
                        style: Theme.of(context).textTheme.bodySmall)
                  else
                    ...upcomingTasks.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(task: t),
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
}
