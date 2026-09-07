import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/roadmap_provider.dart';
import '../widgets/custom_progress_bar.dart';
import '../widgets/module_item.dart';
import 'video_detail_screen.dart';

class RoadmapDetailScreen extends StatelessWidget {
  final String roadmapId;

  const RoadmapDetailScreen({super.key, required this.roadmapId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoadmapProvider>();
    final roadmap = provider.byId(roadmapId);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 20),
            color: AppColors.primaryTeal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  roadmap.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white, fontSize: 22),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '${roadmap.completedCount} dari ${roadmap.totalCount} ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: 'video selesai'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CustomProgressBar(progress: roadmap.progress),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: roadmap.items.length,
              itemBuilder: (context, i) {
                final item = roadmap.items[i];
                return ModuleItem(
                  item: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoDetailScreen(
                        item: item,
                        roadmapId: roadmap.id,
                        topicTitle: roadmap.title,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
