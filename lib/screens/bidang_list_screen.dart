import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/bidang.dart';
import '../providers/bidang_provider.dart';
import 'bidang_detail_screen.dart';

/// Tab "Bidang" — grid semua kategori bidang ilmu.
class BidangListScreen extends StatefulWidget {
  const BidangListScreen({super.key});

  @override
  State<BidangListScreen> createState() => _BidangListScreenState();
}

class _BidangListScreenState extends State<BidangListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<BidangProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              // ─── Header SliverAppBar ───
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: AppColors.primaryTeal,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  title: const Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bidang Ilmu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Pilih bidang yang ingin kamu pelajari',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
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
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Opacity(
                        opacity: 0.08,
                        child: Icon(
                          Icons.category_rounded,
                          size: 140,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Loading / Error / Grid ───
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                )
              else if (provider.errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.maroon),
                        const SizedBox(height: 12),
                        Text(provider.errorMessage!,
                            style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.read<BidangProvider>().loadData(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (provider.bidangList.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 56, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('Belum ada bidang ilmu.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bidang = provider.bidangList[index];
                        return _BidangCard(bidang: bidang);
                      },
                      childCount: provider.bidangList.length,
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

// ─── Card individual bidang ───
class _BidangCard extends StatelessWidget {
  final Bidang bidang;
  const _BidangCard({required this.bidang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BidangDetailScreen(bidang: bidang),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.15),
              width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon dalam lingkaran teal
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(bidang.iconData,
                  color: AppColors.primaryTeal, size: 30),
            ),
            const SizedBox(height: 12),
            // Nama bidang
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                bidang.nama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primaryTeal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            // Jumlah roadmap — badge gold
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${bidang.roadmapCount} Roadmap',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
