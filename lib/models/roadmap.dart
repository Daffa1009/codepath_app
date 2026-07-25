import 'package:flutter/material.dart';
import 'roadmap_item.dart';

enum RoadmapStatus { berjalan, selesai }

/// Sebuah jalur belajar, misal "Dasar Pemrograman" atau "Vibe Coding untuk
/// Pemula". Berisi kumpulan video (RoadmapItem) dari berbagai channel.
class Roadmap {
  final String id;
  final String title;
  final String description;
  final Color iconColor;
  final IconData icon;
  final List<RoadmapItem> items;

  Roadmap({
    required this.id,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.icon,
    required this.items,
  });

  int get completedCount => items.where((e) => e.isCompleted).length;
  int get totalCount => items.length;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  int get progressPercent => (progress * 100).round();

  RoadmapStatus get status =>
      completedCount == totalCount ? RoadmapStatus.selesai : RoadmapStatus.berjalan;

  /// Set of channel unik yang jadi sumber video di roadmap ini.
  Set<String> get sourceChannels => items.map((e) => e.channelName).toSet();
}
