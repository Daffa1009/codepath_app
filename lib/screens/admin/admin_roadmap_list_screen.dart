import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../providers/roadmap_provider.dart';
import 'admin_roadmap_items_screen.dart';

/// Admin screen: daftar semua roadmap + CRUD.
class AdminRoadmapListScreen extends StatefulWidget {
  const AdminRoadmapListScreen({super.key});

  @override
  State<AdminRoadmapListScreen> createState() => _AdminRoadmapListScreenState();
}

class _AdminRoadmapListScreenState extends State<AdminRoadmapListScreen> {
  List<Map<String, dynamic>> _roadmaps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoadmaps();
  }

  Future<void> _loadRoadmaps() async {
    setState(() => _loading = true);
    try {
      // Fetch roadmaps sekaligus count videonya pakai subquery Supabase
      final rows = await Supabase.instance.client
          .from('roadmaps')
          .select('id, title, description, icon_name, roadmap_items(count)')
          .order('created_at');
      setState(() {
        _roadmaps = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat roadmap: $e')),
        );
      }
    }
  }

  int _videoCount(Map<String, dynamic> row) {
    final items = row['roadmap_items'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map && first.containsKey('count')) {
        return (first['count'] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  void _showAddDialog() => _showRoadmapDialog(null);

  void _showEditDialog(Map<String, dynamic> roadmap) =>
      _showRoadmapDialog(roadmap);

  void _showRoadmapDialog(Map<String, dynamic>? existing) {
    final titleCtrl = TextEditingController(
        text: existing?['title'] as String? ?? '');
    final descCtrl = TextEditingController(
        text: existing?['description'] as String? ?? '');
    String selectedIcon =
        existing?['icon_name'] as String? ?? 'code';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Tambah Roadmap' : 'Edit Roadmap',
              style: const TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Judul *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(hintText: 'Masukkan judul roadmap'),
                ),
                const SizedBox(height: 16),
                const Text('Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'Deskripsi roadmap'),
                ),
                const SizedBox(height: 16),
                const Text('Icon',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: RoadmapProvider.availableIcons.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(e.value, size: 20),
                                const SizedBox(width: 8),
                                Text(e.key),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedIcon = v);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder()),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Judul tidak boleh kosong.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await Supabase.instance.client.from('roadmaps').insert({
                      'title': title,
                      'description': descCtrl.text.trim(),
                      'icon_name': selectedIcon,
                    });
                    _showSnack('Roadmap berhasil ditambahkan.');
                  } else {
                    await Supabase.instance.client
                        .from('roadmaps')
                        .update({
                          'title': title,
                          'description': descCtrl.text.trim(),
                          'icon_name': selectedIcon,
                        })
                        .eq('id', existing['id'] as String);
                    _showSnack('Roadmap berhasil diperbarui.');
                  }
                  await _loadRoadmaps();
                } catch (e) {
                  _showSnack('Gagal menyimpan: $e', isError: true);
                }
              },
              child: Text(existing == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> roadmap) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Roadmap?',
            style: TextStyle(
                color: AppColors.maroon, fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin ingin menghapus "${roadmap['title']}"? '
          'Semua video di dalamnya akan ikut terhapus.',
          style: const TextStyle(fontSize: 14),
        ),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('roadmaps')
            .delete()
            .eq('id', roadmap['id'] as String);
        _showSnack('Roadmap berhasil dihapus.');
        await _loadRoadmaps();
      } catch (e) {
        _showSnack('Gagal menghapus: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.maroon : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 20),
              color: AppColors.primaryTeal,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        shape: const CircleBorder()),
                  ),
                  const SizedBox(width: 8),
                  Text('Kelola Roadmap',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white)),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal))
                  : _roadmaps.isEmpty
                      ? const Center(
                          child: Text('Belum ada roadmap. Tambahkan dulu!'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _roadmaps.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final rm = _roadmaps[i];
                            final iconName =
                                rm['icon_name'] as String? ?? 'code';
                            return _RoadmapAdminCard(
                              roadmap: rm,
                              icon: RoadmapProvider.availableIcons[iconName] ??
                                  Icons.menu_book,
                              videoCount: _videoCount(rm),
                              onEdit: () => _showEditDialog(rm),
                              onDelete: () => _confirmDelete(rm),
                              onManageVideos: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminRoadmapItemsScreen(
                                    roadmapId: rm['id'] as String,
                                    roadmapTitle: rm['title'] as String,
                                  ),
                                ),
                              ).then((_) => _loadRoadmaps()),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Roadmap'),
      ),
    );
  }
}

class _RoadmapAdminCard extends StatelessWidget {
  final Map<String, dynamic> roadmap;
  final IconData icon;
  final int videoCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageVideos;

  const _RoadmapAdminCard({
    required this.roadmap,
    required this.icon,
    required this.videoCount,
    required this.onEdit,
    required this.onDelete,
    required this.onManageVideos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roadmap['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('$videoCount video',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: AppColors.gold),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppColors.maroon),
                tooltip: 'Hapus',
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onManageVideos,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryTeal),
                foregroundColor: AppColors.primaryTeal,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Kelola Video'),
            ),
          ),
        ],
      ),
    );
  }
}
