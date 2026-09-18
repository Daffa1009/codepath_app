import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/bidang_provider.dart';
import '../providers/roadmap_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/course_card.dart';
import 'bidang_detail_screen.dart';
import 'profile_screen.dart';
import 'roadmap_detail_screen.dart';
import 'video_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final String namaLengkap;
  final String username;
  final void Function(int)? onTabChange;

  const HomeScreen({
    super.key,
    this.namaLengkap = '',
    this.username = '',
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final roadmapProvider = context.watch<RoadmapProvider>();
    final userProvider = context.watch<UserProvider>();
    
    final lastRoadmap = roadmapProvider.lastInProgress;
    final recommended = roadmapProvider.recommendedNext;

    // Nama tampilan: prioritaskan namaLengkap, fallback ke username dari provider agar tetap sync
    final displayName = userProvider.namaLengkap.isNotEmpty 
        ? userProvider.namaLengkap 
        : (userProvider.username.isNotEmpty ? userProvider.username : 'Pengguna');
    final avatarUrl = userProvider.avatarUrl;

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
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: avatarUrl != null 
                        ? NetworkImage(avatarUrl) 
                        : null,
                      backgroundColor: Colors.white24,
                      child: avatarUrl == null 
                        ? const Icon(Icons.person, color: Colors.white) 
                        : null,
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

                  // Bidang Ilmu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bidang Ilmu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate ke tab Bidang (index 2)
                          if (onTabChange != null) {
                            onTabChange!(2);
                          }
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<BidangProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryTeal, strokeWidth: 2),
                          ),
                        );
                      }

                      if (provider.bidangList.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: const Text('Belum ada bidang tersedia.',
                              style: TextStyle(color: Colors.grey)),
                        );
                      }

                      // Horizontal scroll list bidang (max 6)
                      final displayList = provider.bidangList.take(6).toList();

                      return SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final bidang = displayList[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BidangDetailScreen(bidang: bidang),
                                  ),
                                );
                              },
                              child: Container(
                                width: 90,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        bidang.iconData,
                                        color: AppColors.primaryTeal,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      bidang.nama.split(' ').first, // ambil kata pertama saja
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
