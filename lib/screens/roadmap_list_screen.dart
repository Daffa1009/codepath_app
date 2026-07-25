import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/roadmap.dart';
import '../providers/roadmap_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/course_card.dart';
import 'roadmap_detail_screen.dart';

enum _Filter { semua, selesai, berjalan }

class RoadmapListScreen extends StatefulWidget {
  const RoadmapListScreen({super.key});

  @override
  State<RoadmapListScreen> createState() => _RoadmapListScreenState();
}

class _RoadmapListScreenState extends State<RoadmapListScreen> {
  _Filter _filter = _Filter.semua;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoadmapProvider>();

    List<Roadmap> filtered;
    switch (_filter) {
      case _Filter.selesai:
        filtered = provider.selesai;
        break;
      case _Filter.berjalan:
        filtered = provider.berjalan;
        break;
      case _Filter.semua:
        filtered = provider.roadmaps;
        break;
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(title: 'Jalur Belajar'),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _filterChip('Semua', _Filter.semua),
                const SizedBox(width: 10),
                _filterChip('Selesai', _Filter.selesai),
                const SizedBox(width: 10),
                _filterChip('Berjalan', _Filter.berjalan),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final roadmap = filtered[i];
                return CourseCard(
                  roadmap: roadmap,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoadmapDetailScreen(roadmapId: roadmap.id),
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

  Widget _filterChip(String label, _Filter value) {
    final active = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.primaryTeal,
      labelStyle: TextStyle(
        color: active ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      shape: const StadiumBorder(),
    );
  }
}
