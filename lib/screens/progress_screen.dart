import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/progress_provider.dart';
import '../providers/roadmap_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yakin ingin keluar?',
            style: TextStyle(
                color: AppColors.maroon, fontWeight: FontWeight.w700)),
        content: const Text('Kamu akan kembali ke halaman login.',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: Colors.white,
                shape: const StadiumBorder()),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (!mounted) return;
      context.read<UserProvider>().clearUser();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final roadmapProvider = context.watch<RoadmapProvider>();

    return SafeArea(
      child: Column(
        children: [
          // Custom header dengan tombol logout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
            color: AppColors.primaryTeal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Keluar',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatCard(
                        value: '${roadmapProvider.completedRoadmaps}',
                        label: 'Jalur\nSelesai',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        value: '${progress.videosWatched}',
                        label: 'Video\nDitonton',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        value: '${progress.streakDays}',
                        label: 'Hari\nBeruntun',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Aktivitas Belajar Mingguan',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADADA),
                      borderRadius:
                          BorderRadius.circular(AppRadius.card),
                    ),
                    child: progress.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryTeal))
                        : Column(
                            children: progress.weeklyActivity.entries
                                .map((e) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 14),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            child: Text(e.key,
                                                style: Theme.of(
                                                        context)
                                                    .textTheme
                                                    .bodyMedium),
                                          ),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.pill),
                                              child: LayoutBuilder(
                                                builder: (context,
                                                        constraints) =>
                                                    Stack(
                                                  children: [
                                                    Container(
                                                        height: 14,
                                                        color:
                                                            Colors.white),
                                                    Container(
                                                      height: 14,
                                                      width: constraints
                                                              .maxWidth *
                                                          e.value,
                                                      color: AppColors
                                                          .primaryTeal,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
