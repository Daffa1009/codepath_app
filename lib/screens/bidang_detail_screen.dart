import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/bidang.dart';
import '../providers/roadmap_provider.dart';
import '../widgets/course_card.dart';
import 'roadmap_detail_screen.dart';

/// Halaman detail bidang — menampilkan semua roadmap dalam bidang ini.
class BidangDetailScreen extends StatelessWidget {
  final Bidang bidang;
  const BidangDetailScreen({super.key, required this.bidang});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<RoadmapProvider>(
        builder: (context, provider, _) {
          final roadmaps = provider.roadmaps
              .where((r) => r.bidangId == bidang.id)
              .toList();

          return CustomScrollView(
            slivers: [
              // ─── SliverAppBar selaras dengan beranda (primaryTeal) ───
              SliverAppBar(
                expandedHeight: 170,
                pinned: true,
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                  title: Text(
                    bidang.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryTeal,
                          Color(0xFF1A5C54),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Icon besar transparan sebagai background decoration
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Opacity(
                            opacity: 0.12,
                            child: Icon(
                              bidang.iconData,
                              size: 140,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Icon dan info di tengah
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 56),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  bidang.iconData,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (bidang.deskripsi != null)
                                Expanded(
                                  child: Text(
                                    bidang.deskripsi!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Section title ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Roadmap Tersedia',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${roadmaps.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Roadmap list / empty state ───
              if (roadmaps.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 56,
                            color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada roadmap untuk bidang ini.',
                          style: TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final roadmap = roadmaps[index];
                        return CourseCard(
                          roadmap: roadmap,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                body: RoadmapDetailScreen(
                                  roadmapId: roadmap.id,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: roadmaps.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
