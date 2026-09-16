import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../providers/bidang_provider.dart';

/// Admin screen: daftar semua bidang + CRUD (tambah, edit, hapus).
class AdminBidangScreen extends StatefulWidget {
  const AdminBidangScreen({super.key});

  @override
  State<AdminBidangScreen> createState() => _AdminBidangScreenState();
}

class _AdminBidangScreenState extends State<AdminBidangScreen> {
  List<Map<String, dynamic>> _bidangList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBidang();
  }

  Future<void> _loadBidang() async {
    setState(() => _loading = true);
    try {
      final bidangData = await Supabase.instance.client
          .from('bidang')
          .select()
          .order('sort_order');

      final roadmapData = await Supabase.instance.client
          .from('roadmaps')
          .select('bidang_id')
          .not('bidang_id', 'is', null);

      final countMap = <String, int>{};
      for (final r in roadmapData) {
        final bid = r['bidang_id'] as String? ?? '';
        if (bid.isNotEmpty) {
          countMap[bid] = (countMap[bid] ?? 0) + 1;
        }
      }

      final rows = (bidangData as List).map((item) {
        return {
          ...Map<String, dynamic>.from(item),
          'roadmap_count': countMap[item['id'] as String] ?? 0,
        };
      }).toList();

      setState(() {
        _bidangList = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Gagal memuat bidang: $e', isError: true);
    }
  }

  int _roadmapCount(Map<String, dynamic> row) {
    return row['roadmap_count'] as int? ?? 0;
  }

  void _showAddDialog() => _showBidangDialog(null);
  void _showEditDialog(Map<String, dynamic> b) => _showBidangDialog(b);

  void _showBidangDialog(Map<String, dynamic>? existing) {
    final namaCtrl =
        TextEditingController(text: existing?['nama'] as String? ?? '');
    final descCtrl =
        TextEditingController(text: existing?['deskripsi'] as String? ?? '');
    final warnaCtrl =
        TextEditingController(text: existing?['warna'] as String? ?? '#0D3B36');
    final sortCtrl = TextEditingController(
        text: (existing?['sort_order'] as int? ?? 0).toString());
    String selectedIcon = existing?['icon_name'] as String? ?? 'folder';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? 'Tambah Bidang' : 'Edit Bidang',
            style: const TextStyle(
                color: AppColors.primaryTeal, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama
                const Text('Nama Bidang *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: namaCtrl,
                  decoration:
                      const InputDecoration(hintText: 'cth. Frontend Development'),
                ),
                const SizedBox(height: 14),

                // Deskripsi
                const Text('Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(hintText: 'Deskripsi singkat bidang'),
                ),
                const SizedBox(height: 14),

                // Icon
                const Text('Icon',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: BidangProvider.availableIcons.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(children: [
                              Icon(e.value, size: 20),
                              const SizedBox(width: 8),
                              Text(e.key),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedIcon = v);
                  },
                ),
                const SizedBox(height: 14),

                // Warna hex
                const Text('Warna (hex)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: warnaCtrl,
                  decoration: const InputDecoration(hintText: '#1a73e8'),
                ),
                const SizedBox(height: 14),

                // Sort order
                const Text('Urutan (sort_order)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '1'),
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
                final nama = namaCtrl.text.trim();
                if (nama.isEmpty) {
                  _showSnack('Nama bidang tidak boleh kosong.', isError: true);
                  return;
                }
                final sortOrder = int.tryParse(sortCtrl.text) ?? 0;
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await Supabase.instance.client.from('bidang').insert({
                      'nama': nama,
                      'deskripsi': descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      'icon_name': selectedIcon,
                      'warna': warnaCtrl.text.trim().isEmpty
                          ? null
                          : warnaCtrl.text.trim(),
                      'sort_order': sortOrder,
                    });
                    _showSnack('Bidang berhasil ditambahkan.');
                  } else {
                    await Supabase.instance.client
                        .from('bidang')
                        .update({
                          'nama': nama,
                          'deskripsi': descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          'icon_name': selectedIcon,
                          'warna': warnaCtrl.text.trim().isEmpty
                              ? null
                              : warnaCtrl.text.trim(),
                          'sort_order': sortOrder,
                        })
                        .eq('id', existing['id'] as String);
                    _showSnack('Bidang berhasil diperbarui.');
                  }
                  await _loadBidang();
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

  Future<void> _confirmDelete(Map<String, dynamic> bidang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Bidang?',
            style: TextStyle(
                color: AppColors.maroon, fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin ingin menghapus "${bidang['nama']}"? '
          'Roadmap yang terhubung tidak akan terhapus, hanya relasinya.',
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
            .from('bidang')
            .delete()
            .eq('id', bidang['id'] as String);
        _showSnack('Bidang berhasil dihapus.');
        await _loadBidang();
      } catch (e) {
        _showSnack('Gagal menghapus: $e', isError: true);
      }
    }
  }

  void _showAssignRoadmapsDialog(Map<String, dynamic> bidang) {
    _showAssignRoadmapsDialogInternal(
        bidang['id'] as String, bidang['nama'] as String);
  }

  Future<void> _showAssignRoadmapsDialogInternal(
      String bidangId, String bidangNama) async {
    // Simpan data roadmap di luar dialog agar bisa dimutasi
    final List<Map<String, dynamic>> roadmaps = [];
    final loading = ValueNotifier<bool>(true);

    Supabase.instance.client
        .from('roadmaps')
        .select('id, title, bidang_id')
        .order('created_at')
        .then((data) {
      roadmaps.addAll(List<Map<String, dynamic>>.from(data));
      loading.value = false;
    }).catchError((e) {
      _showSnack('Gagal memuat roadmap: $e', isError: true);
      loading.value = false;
    });

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Kelola Roadmap — $bidangNama',
            style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 500,
            height: 420,
            child: ValueListenableBuilder<bool>(
              valueListenable: loading,
              builder: (c, isLoading, _) {
                if (isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryTeal));
                }
                if (roadmaps.isEmpty) {
                  return const Center(
                      child: Text('Belum ada roadmap (Jalur Belajar).'));
                }
                return ListView.builder(
                  itemCount: roadmaps.length,
                  itemBuilder: (c, i) {
                    final rm = roadmaps[i];
                    final isChecked = rm.containsKey('temp_checked')
                        ? rm['temp_checked'] as bool
                        : rm['bidang_id'] == bidangId;
                    return CheckboxListTile(
                      activeColor: AppColors.primaryTeal,
                      value: isChecked,
                      title: Text(rm['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark)),
                      subtitle: Text(
                        rm['bidang_id'] == bidangId
                            ? 'Sudah di bidang ini'
                            : rm['bidang_id'] != null
                                ? 'Di bidang lain'
                                : 'Belum di-assign',
                        style: TextStyle(
                          fontSize: 11,
                          color: rm['bidang_id'] == bidangId
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                      onChanged: (v) {
                        setDialogState(
                            () => rm['temp_checked'] = v ?? false);
                      },
                    );
                  },
                );
              },
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
                Navigator.pop(ctx);
                try {
                  for (final rm in roadmaps) {
                    final checked = rm.containsKey('temp_checked')
                        ? rm['temp_checked'] as bool
                        : rm['bidang_id'] == bidangId;
                    final currentBidang = rm['bidang_id'];

                    if (checked && currentBidang != bidangId) {
                      // Assign ke bidang ini
                      await Supabase.instance.client
                          .from('roadmaps')
                          .update({'bidang_id': bidangId})
                          .eq('id', rm['id'] as String);
                    } else if (!checked && currentBidang == bidangId) {
                      // Lepas dari bidang ini
                      await Supabase.instance.client
                          .from('roadmaps')
                          .update({'bidang_id': null})
                          .eq('id', rm['id'] as String);
                    }
                  }
                  _showSnack('Roadmap berhasil diperbarui.');
                  await _loadBidang();
                } catch (e) {
                  _showSnack('Gagal menyimpan: $e', isError: true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.maroon : AppColors.success,
    ));
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
                  Text('Kelola Bidang',
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
                  : _bidangList.isEmpty
                      ? const Center(
                          child: Text('Belum ada bidang. Tambahkan dulu!'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _bidangList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final b = _bidangList[i];
                            final iconName =
                                b['icon_name'] as String? ?? 'folder';
                            final warnaHex = b['warna'] as String?;
                            Color warnaColor = AppColors.primaryTeal;
                            if (warnaHex != null) {
                              try {
                                warnaColor = Color(int.parse(
                                    warnaHex.replaceFirst('#', '0xFF')));
                              } catch (_) {}
                            }
                            final iconData =
                                BidangProvider.availableIcons[iconName] ??
                                    Icons.folder_rounded;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          warnaColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(iconData,
                                        color: warnaColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(b['nama'] as String,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        Text(
                                            '${_roadmapCount(b)} roadmap  •  urutan: ${b['sort_order']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showEditDialog(b),
                                    icon: const Icon(Icons.edit,
                                        color: AppColors.gold),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(b),
                                    icon: const Icon(Icons.delete,
                                        color: AppColors.maroon),
                                    tooltip: 'Hapus',
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showAssignRoadmapsDialog(b),
                                    icon: const Icon(
                                        Icons.library_books_rounded,
                                        color: AppColors.primaryTeal),
                                    tooltip: 'Kelola Roadmap',
                                  ),
                                ],
                              ),
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
        label: const Text('Tambah Bidang'),
      ),
    );
  }
}
