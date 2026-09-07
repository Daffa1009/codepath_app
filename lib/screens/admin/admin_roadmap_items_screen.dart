import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import 'admin_chapter_screen.dart';

/// Admin screen: daftar video (roadmap_items) dalam 1 roadmap + CRUD.
class AdminRoadmapItemsScreen extends StatefulWidget {
  final String roadmapId;
  final String roadmapTitle;

  const AdminRoadmapItemsScreen({
    super.key,
    required this.roadmapId,
    required this.roadmapTitle,
  });

  @override
  State<AdminRoadmapItemsScreen> createState() =>
      _AdminRoadmapItemsScreenState();
}

class _AdminRoadmapItemsScreenState extends State<AdminRoadmapItemsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('roadmap_items')
          .select('id, title, channel_name, youtube_url, duration_minutes, sort_order')
          .eq('roadmap_id', widget.roadmapId)
          .order('sort_order');
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Gagal memuat video: $e', isError: true);
    }
  }

  void _showAddDialog() => _showItemDialog(null);
  void _showEditDialog(Map<String, dynamic> item) => _showItemDialog(item);

  void _showItemDialog(Map<String, dynamic>? existing) {
    final titleCtrl = TextEditingController(
        text: existing?['title'] as String? ?? '');
    final channelCtrl = TextEditingController(
        text: existing?['channel_name'] as String? ?? '');
    final urlCtrl = TextEditingController(
        text: existing?['youtube_url'] as String? ?? '');
    final durationCtrl = TextEditingController(
        text: existing != null
            ? '${existing['duration_minutes'] ?? 0}'
            : '');
    final orderCtrl = TextEditingController(
        text: existing != null ? '${existing['sort_order'] ?? 0}' : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        scrollable: true,
        title: Text(existing == null ? 'Tambah Video' : 'Edit Video',
            style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogField('Judul *', titleCtrl, hint: 'Judul video'),
            const SizedBox(height: 12),
            _dialogField('Channel', channelCtrl, hint: 'Nama channel YouTube'),
            const SizedBox(height: 12),
            _dialogField('URL YouTube *', urlCtrl,
                hint: 'https://youtu.be/...'),
            const SizedBox(height: 12),
            _dialogField('Durasi (menit)', durationCtrl,
                hint: '15', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _dialogField('Urutan (sort_order)', orderCtrl,
                hint: '0', keyboard: TextInputType.number),
          ],
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
              final url = urlCtrl.text.trim();
              if (title.isEmpty || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Judul dan URL tidak boleh kosong.')),
                );
                return;
              }
              Navigator.pop(ctx);
              final payload = {
                'roadmap_id': widget.roadmapId,
                'title': title,
                'channel_name': channelCtrl.text.trim(),
                'youtube_url': url,
                'duration_minutes':
                    int.tryParse(durationCtrl.text.trim()) ?? 0,
                'sort_order': int.tryParse(orderCtrl.text.trim()) ?? 0,
              };
              try {
                if (existing == null) {
                  await Supabase.instance.client
                      .from('roadmap_items')
                      .insert(payload);
                  _showSnack('Video berhasil ditambahkan.');
                } else {
                  await Supabase.instance.client
                      .from('roadmap_items')
                      .update({
                        'title': title,
                        'channel_name': channelCtrl.text.trim(),
                        'youtube_url': url,
                        'duration_minutes':
                            int.tryParse(durationCtrl.text.trim()) ?? 0,
                        'sort_order':
                            int.tryParse(orderCtrl.text.trim()) ?? 0,
                      })
                      .eq('id', existing['id'] as String);
                  _showSnack('Video berhasil diperbarui.');
                }
                await _loadItems();
              } catch (e) {
                _showSnack('Gagal menyimpan: $e', isError: true);
              }
            },
            child: Text(existing == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Video?',
            style: TextStyle(
                color: AppColors.maroon, fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin ingin menghapus "${item['title']}"?',
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
            .from('roadmap_items')
            .delete()
            .eq('id', item['id'] as String);
        _showSnack('Video berhasil dihapus.');
        await _loadItems();
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

  Widget _dialogField(String label, TextEditingController ctrl,
      {String hint = '',
      TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            shape: const CircleBorder()),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kelola Video',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Text(
                      widget.roadmapTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal))
                  : _items.isEmpty
                      ? const Center(
                          child: Text('Belum ada video. Tambahkan dulu!'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            return _VideoAdminCard(
                              item: item,
                              onChapter: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminChapterScreen(
                                    itemId: item['id'] as String,
                                    videoTitle: item['title'] as String? ?? '',
                                  ),
                                ),
                              ),
                              onEdit: () => _showEditDialog(item),
                              onDelete: () => _confirmDelete(item),
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
        label: const Text('Tambah Video'),
      ),
    );
  }
}

class _VideoAdminCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onChapter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VideoAdminCard({
    required this.item,
    required this.onChapter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final order = item['sort_order'] as int? ?? 0;
    final duration = item['duration_minutes'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${order + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String? ?? '',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${item['channel_name'] ?? ''} · $duration Menit',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onChapter,
            icon: const Icon(Icons.format_list_numbered,
                color: AppColors.gold, size: 20),
            tooltip: 'Kelola Chapter',
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit,
                color: AppColors.primaryTeal, size: 20),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon:
                const Icon(Icons.delete, color: AppColors.maroon, size: 20),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }
}
