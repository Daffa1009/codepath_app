import 'package:flutter/material.dart';
import '../models/roadmap.dart';
import '../models/roadmap_item.dart';
import '../models/task_item.dart';

/// Data dummy untuk pengembangan UI sebelum backend CodeIgniter 4 tersedia.
/// Nantinya ini akan digantikan oleh hasil fetch dari ApiService.
List<Roadmap> buildDummyRoadmaps() {
  return [
    Roadmap(
      id: 'rm1',
      title: 'Dasar Pemrograman',
      description:
          'Fondasi logika, sintaks dasar, dan konsep pemrograman untuk pemula total.',
      iconColor: const Color(0xFFC9A227),
      icon: Icons.code,
      items: [
        RoadmapItem(
          id: 'i1',
          title: 'Apa itu Pemrograman? (Untuk Pemula)',
          channelName: 'Programmer Zaman Now',
          youtubeUrl: 'https://youtu.be/2hiaZghRYHk?si=Ehm0BR1HdxB6GCx4',
          durationMinutes: 12,
          isCompleted: true,
        ),
        RoadmapItem(
          id: 'i2',
          title: 'Variabel, Tipe Data & Operator',
          channelName: 'Web Programming UNPAS',
          youtubeUrl: 'https://www.youtube.com/results?search_query=variabel+tipe+data+operator',
          durationMinutes: 18,
          isCompleted: true,
        ),
        RoadmapItem(
          id: 'i3',
          title: 'Percabangan (If-Else) dan Studi Kasus',
          channelName: 'Sandika Galih',
          youtubeUrl: 'https://www.youtube.com/results?search_query=percabangan+if+else+sandika+galih',
          durationMinutes: 15,
          isCompleted: false,
        ),
        RoadmapItem(
          id: 'i4',
          title: 'Perulangan (Looping) dari Nol',
          channelName: 'Programmer Zaman Now',
          youtubeUrl: 'https://www.youtube.com/results?search_query=perulangan+looping+pemrograman',
          durationMinutes: 20,
          isCompleted: false,
        ),
      ],
    ),
    Roadmap(
      id: 'rm2',
      title: 'Vibe Coding untuk Pemula',
      description:
          'Belajar membangun aplikasi dengan bantuan AI coding tools — santai tapi paham konsepnya.',
      iconColor: const Color(0xFF0D3B36),
      icon: Icons.auto_awesome,
      items: [
        RoadmapItem(
          id: 'i5',
          title: 'Kenalan dengan Vibe Coding',
          channelName: 'Sandika Galih',
          youtubeUrl: 'https://www.youtube.com/results?search_query=vibe+coding+sandika+galih',
          durationMinutes: 14,
          isCompleted: true,
        ),
        RoadmapItem(
          id: 'i6',
          title: 'Bikin Aplikasi Pertama dengan AI',
          channelName: 'Sandika Galih',
          youtubeUrl: 'https://www.youtube.com/results?search_query=bikin+aplikasi+ai+vibe+coding',
          durationMinutes: 22,
          isCompleted: false,
        ),
        RoadmapItem(
          id: 'i7',
          title: 'Menulis Prompt yang Efektif untuk Coding',
          channelName: 'Kelas Terbuka',
          youtubeUrl: 'https://www.youtube.com/results?search_query=prompt+efektif+untuk+coding',
          durationMinutes: 16,
          isCompleted: false,
        ),
      ],
    ),
    Roadmap(
      id: 'rm3',
      title: 'Web Dev Pemula',
      description: 'HTML, CSS, dan JavaScript dasar untuk membangun halaman web pertamamu.',
      iconColor: const Color(0xFFC9A227),
      icon: Icons.web,
      items: [
        RoadmapItem(
          id: 'i8',
          title: 'HTML Dasar dari Nol',
          channelName: 'Web Programming UNPAS',
          youtubeUrl: 'https://www.youtube.com/results?search_query=html+dasar+web+programming+unpas',
          durationMinutes: 25,
          isCompleted: true,
        ),
        RoadmapItem(
          id: 'i9',
          title: 'CSS Layout: Flexbox & Grid',
          channelName: 'Programmer Zaman Now',
          youtubeUrl: 'https://www.youtube.com/results?search_query=css+flexbox+grid+pemula',
          durationMinutes: 28,
          isCompleted: true,
        ),
        RoadmapItem(
          id: 'i10',
          title: 'JavaScript Dasar: Interaktif di Web',
          channelName: 'Sandika Galih',
          youtubeUrl: 'https://www.youtube.com/results?search_query=javascript+dasar+sandika+galih',
          durationMinutes: 30,
          isCompleted: true,
        ),
      ],
    ),
  ];
}

List<TaskItem> buildDummyTasks() {
  final now = DateTime.now();
  return [
    TaskItem(
      id: 't1',
      courseTitle: 'Dasar Pemrograman',
      title: 'Latihan Percabangan',
      description: 'Buat program sederhana kalkulator nilai dengan if-else.',
      deadline: now.add(const Duration(days: 2)),
      urgency: TaskUrgency.mendatang,
      type: TaskType.praktik,
    ),
    TaskItem(
      id: 't2',
      courseTitle: 'Vibe Coding untuk Pemula',
      title: 'Kuis: Menulis Prompt',
      description: 'Kuis singkat tentang teknik menulis prompt yang efektif.',
      deadline: now.add(const Duration(hours: 6)),
      urgency: TaskUrgency.mendesak,
      type: TaskType.kuis,
    ),
    TaskItem(
      id: 't3',
      courseTitle: 'Web Dev Pemula',
      title: 'Praktik CSS Layout',
      description: 'Susun ulang halaman profil pakai Flexbox.',
      deadline: now.add(const Duration(days: 1)),
      urgency: TaskUrgency.mendesak,
      type: TaskType.praktik,
    ),
  ];
}

/// Aktivitas belajar mingguan (dummy) untuk halaman Progress.
/// Value 0.0 - 1.0 merepresentasikan proporsi target harian yang tercapai.
final Map<String, double> dummyWeeklyActivity = {
  'Senin': 0.6,
  'Selasa': 0.8,
  'Rabu': 1.0,
  'Kamis': 0.7,
  'Jumat': 0.0,
};
