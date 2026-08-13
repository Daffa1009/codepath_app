import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/roadmap_provider.dart';
import '../providers/task_provider.dart';
import '../providers/progress_provider.dart';
import '../services/auth_result.dart';
import '../widgets/liquid_nav_bar.dart';
import 'home_screen.dart';
import 'roadmap_list_screen.dart';
import 'task_list_screen.dart';
import 'progress_screen.dart';

/// Shell utama aplikasi setelah login — menampung 4 tab:
/// Beranda, Jalur Belajar, Latihan, Progress.
/// Menggunakan LiquidNavBar dengan efek cekungan bezier smooth.
class MainNavScreen extends StatefulWidget {
  final AuthResult? user;

  const MainNavScreen({super.key, this.user});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  /// Daftar tab untuk liquid navigation bar.
  static const _navItems = [
    LiquidNavItem(icon: Icons.home_rounded, label: 'Beranda'),
    LiquidNavItem(icon: Icons.collections_bookmark_rounded, label: 'Jalur Belajar'),
    LiquidNavItem(icon: Icons.check_circle_rounded, label: 'Latihan'),
    LiquidNavItem(icon: Icons.bar_chart_rounded, label: 'Progress'),
  ];

  @override
  void initState() {
    super.initState();
    // Muat data dari Supabase setelah frame pertama selesai dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    await Future.wait([
      context.read<RoadmapProvider>().loadData(),
      context.read<TaskProvider>().loadData(),
      context.read<ProgressProvider>().loadData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        namaLengkap: widget.user?.namaLengkap ?? '',
        username: widget.user?.username ?? '',
      ),
      const RoadmapListScreen(),
      const TaskListScreen(),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: _navItems,
      ),
    );
  }
}
